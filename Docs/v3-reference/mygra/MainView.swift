//
//  MainView.swift
//  MygraComposition
//
//  The adaptive four-tab shell: a tab bar on iPhone and a sidebar on iPad/Mac through
//  `.sidebarAdaptable`, with each tab owning its own navigation stack. The tab bar's
//  bottom accessory (iOS 26+) is a persistent status strip — the live ongoing-migraine
//  timer, or a one-tap Log a Migraine action (the header owns the status text). The new-migraine sheet
//  and assistant are presented here, as is the Mygra Plus paywall whenever a gated
//  feature asks for it, and every deep link routes through `AppRouter`.
//

#if os(iOS)
import SwiftUI
import MygraCore
import MygraDesignSystem
import MygraFeatureShared
import MygraFeatureDashboard
import MygraFeatureCalendar
import MygraFeatureMigraines
import MygraFeatureAssistant
import MygraFeatureSettings
import MygraServices

struct MainView: View {
    @Environment(MigraineDataModel.self) private var migraineData
    @Environment(InsightModel.self) private var insights
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(AttackModeModel.self) private var attackMode

    let session: SessionController

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var navigation = NavigationModel()
    /// The page shown in the unfolded Duo's Settings split view.
    @State private var settingsSelection: SettingsDestination? = .profile

    private var router: AppRouter { session.router }

    /// The unfolded iPhone Duo shows Settings as a split view (list left of the hinge, the
    /// selected page right of it). DEBUG: `-MygraDebugForceSplit YES` shows it on any
    /// regular-width device so it can be checked without an unfolded Duo.
    private var usesSettingsSplitView: Bool {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "MygraDebugForceSplit") { return horizontalSizeClass == .regular }
        #endif
        return PhoneDuo.isDuo && horizontalSizeClass == .regular
    }

    /// The Duo's tab bar is a vertical strip on the trailing edge, so the system bottom
    /// accessory (which spans the window and would run under the hinge) is replaced there by
    /// a strip kept in the leading pane.
    private var showsStatusStrip: Bool { router.selectedTab != .settings }

    var body: some View {
        @Bindable var router = router
        @Bindable var paywall = session.paywall
        @Bindable var attackMode = attackMode
        TabView(selection: $router.selectedTab) {
            Tab(AppTab.dashboard.title, systemImage: AppTab.dashboard.systemImage, value: .dashboard) {
                NavigationStack(path: $navigation.dashboardPath) {
                    DashboardView()
                        .navigationTitle("Mygra")
                        .statusSubtitle()
                        .newMigraineToolbarIfNeeded(self)
                        .navigationDestination(for: UUID.self, destination: migraineDestination)
                }
                .duoStripClearance(isEnabled: showsStatusStrip)
            }

            Tab(AppTab.calendar.title, systemImage: AppTab.calendar.systemImage, value: .calendar) {
                NavigationStack(path: $navigation.calendarPath) {
                    MigraineCalendarView()
                        .newMigraineToolbarIfNeeded(self)
                        .navigationDestination(for: UUID.self, destination: migraineDestination)
                }
                .duoStripClearance(isEnabled: showsStatusStrip)
            }

            Tab(AppTab.list.title, systemImage: AppTab.list.systemImage, value: .list) {
                NavigationStack(path: $navigation.listPath) {
                    MigraineListView()
                        .navigationTitle(AppTab.list.title)
                        .newMigraineToolbarIfNeeded(self)
                        .navigationDestination(for: UUID.self, destination: migraineDestination)
                }
                .duoStripClearance(isEnabled: showsStatusStrip)
            }

            Tab(AppTab.settings.title, systemImage: AppTab.settings.systemImage, value: .settings) {
                if usesSettingsSplitView {
                    SettingsSplitView(selection: $settingsSelection)
                } else {
                    NavigationStack(path: $navigation.settingsPath) {
                        SettingsView()
                            .navigationTitle(AppTab.settings.title)
                            .statusSubtitle()
                            .navigationDestination(for: SettingsDestination.self) { SettingsDestinationView(destination: $0) }
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .minimizeTabBarOnScrollIfAvailable()
        // The status strip carries the Log action, so it only belongs on the tabs where
        // logging happens; on Settings it just covers section text.
        .tabViewBottomAccessoryIfAvailable(isEnabled: showsStatusStrip && !PhoneDuo.isDuo) {
            if #available(iOS 26.0, *) {
                MigraineStatusAccessory(
                    ongoing: migraineData.ongoingMigraine,
                    onOpenOngoing: { id in navigateToMigraine(id: id) },
                    onLog: handleAddTapped
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if PhoneDuo.isDuo, showsStatusStrip, #available(iOS 26.0, *) {
                DuoStatusStrip(
                    ongoing: migraineData.ongoingMigraine,
                    onOpenOngoing: { id in navigateToMigraine(id: id) },
                    onLog: handleAddTapped
                )
            }
        }
        .tint(router.selectedTab.color())
        .sheet(isPresented: $navigation.showingEntrySheet) {
            MigraineEntryView { migraine in
                logNewMigraine(migraine)
            }
            .interactiveDismissDisabled(true)
            .presentationDetents([.large])
        }
        .sheet(isPresented: $navigation.showingAssistant) {
            if #available(iOS 26.0, *) {
                MigraineAssistantView()
                    .presentationSizing(.page)
            }
        }
        .fullScreenCover(isPresented: $attackMode.isPresented) {
            AttackModeView()
        }
        .sheet(item: $paywall.request) { request in
            PaywallView(feature: request.feature)
                .presentationSizing(.page)
        }
        .onChange(of: subscription.isGrandfathered) { _, _ in
            session.showEarlySupporterThanksIfNeeded()
        }
        .alert("Ongoing Migraine", isPresented: $navigation.showingOngoingAlert) {
            Button("OK", role: .cancel) {}
            if let ongoing = migraineData.ongoingMigraine {
                Button("View Ongoing") { navigateToMigraine(id: ongoing.id) }
            }
        } message: {
            Text("You already have an ongoing migraine. End it before starting a new one.")
        }
        .onChange(of: router.pendingDeepLink) { _, newLink in
            handleDeepLink(newLink)
        }
        .onAppear {
            #if DEBUG
            // Screenshots: `-MygraDebugTab Dashboard|Calendar|Migraines|Settings`.
            if let name = UserDefaults.standard.string(forKey: "MygraDebugTab"), let tab = AppTab(rawValue: name) {
                router.selectedTab = tab
            }
            // Duo screenshots: `-MygraDebugPresent entry|paywall|attack|assistant`.
            switch UserDefaults.standard.string(forKey: "MygraDebugPresent") {
            case "entry": navigation.showingEntrySheet = true
            case "paywall": session.paywall.present(nil)
            case "attack": attackMode.enter()
            default: break
            }
            #endif
            handleDeepLink(router.pendingDeepLink)
            session.showEarlySupporterThanksIfNeeded()
        }
    }

    // MARK: - Toolbar

    /// The top-trailing "New Migraine" action on the Dashboard, Calendar, and Migraines
    /// pages, only installed before iOS 26. From iOS 26 the tab-bar accessory pill is the
    /// single entry point (log, or open the ongoing migraine) on iPhone and iPad, and ⌘N
    /// still works through the menu-bar command. While a migraine is ongoing the button
    /// becomes a shortcut to it.
    @ToolbarContentBuilder
    fileprivate var newMigraineToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if let ongoing = migraineData.ongoingMigraine {
                Button {
                    navigateToMigraine(id: ongoing.id)
                } label: {
                    Label("Ongoing Migraine", systemImage: "waveform.path.ecg")
                        .symbolEffect(.pulse, options: .repeating)
                }
                .tint(.mygraPurple)
                .accessibilityIdentifier("ongoingMigraineButton")
                .accessibilityLabel(Text("Ongoing migraine in progress, tap to view"))
            } else {
                Button {
                    handleAddTapped()
                } label: {
                    Label("New Migraine", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .accessibilityIdentifier("addEntryButton")
                .accessibilityLabel(Text("Log a new migraine"))
            }
        }
    }

    // MARK: - Navigation

    @ContentBuilder
    private func migraineDestination(for id: UUID) -> some View {
        if let migraine = migraineData.migraine(withID: id) {
            MigraineDetailView(migraine: migraine)
                .userActivity(UserActivityType.viewingMigraine) { activity in
                    session.annotateViewingActivity(activity, migraineID: id)
                }
        } else {
            ContentUnavailableView(
                "Migraine Not Found",
                systemImage: "exclamationmark.triangle",
                description: Text("The selected migraine could not be loaded.")
            )
        }
    }

    private func handleDeepLink(_ link: DeepLink?) {
        guard let link else { return }
        defer { router.pendingDeepLink = nil }

        switch link {
        case .newMigraine: handleAddTapped()
        case .home, .calendar, .list, .settings: break // the router already selected the tab
        case .tags:
            settingsSelection = .tags
            navigation.settingsPath = usesSettingsSplitView ? NavigationPath() : NavigationPath([SettingsDestination.tags])
        case .migraine(let id): navigateToMigraine(id: id)
        case .assistant:
            guard #available(iOS 26.0, *), insights.supportsAppleIntelligence else { break }
            if insights.canUseIntelligence {
                navigation.showingAssistant = true
                Task { await insights.startChat() }
            } else {
                session.paywall.present(.assistant)
            }
        case .endOngoing:
            migraineData.endOngoing()
        case .attackMode:
            // Starts an attack when none is active, otherwise opens the one in progress.
            attackMode.enter()
        case .finishLogging(let id):
            attackMode.requestFinish(id)
            navigateToMigraine(id: id)
        }
    }

    private func handleAddTapped() {
        if migraineData.ongoingMigraine != nil {
            navigation.showingOngoingAlert = true
        } else {
            navigation.showingEntrySheet = true
        }
    }

    private func logNewMigraine(_ migraine: Migraine) {
        navigation.showingEntrySheet = false
        guard migraineData.log(migraine) else { return }
        navigateToMigraine(id: migraine.id)
    }

    /// Shows a migraine's detail in the Migraines tab, pushing once even when several
    /// sources (toolbar, accessory, deep link) ask for the same record.
    private func navigateToMigraine(id: UUID) {
        router.select(.list)
        guard navigation.listPath.count == 0 || navigation.lastPushedMigraineID != id else { return }
        navigation.listPath = NavigationPath([id])
        navigation.lastPushedMigraineID = id
    }
}

// MARK: - Status accessory

/// The tab-bar bottom accessory. Always present, so it always says something useful:
/// while a migraine is in progress, a pulsing waveform with the live elapsed time that
/// opens the detail screen; otherwise just the Log a Migraine action. When the tab bar minimizes on scroll the accessory moves inline next to the
/// selected tab, so the inline placement drops to the essentials.
@available(iOS 26.0, *)
private struct MigraineStatusAccessory: View {
    let ongoing: Migraine?
    let onOpenOngoing: (UUID) -> Void
    let onLog: () -> Void
    /// True on the Duo, where the strip's own tinted glass is the control's single edge and
    /// the label is white. Elsewhere the system accessory's glass is the one edge and the
    /// label takes the brand colour (no second, filled capsule inside it).
    var onTintedSurface: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// On regular width (iPad) the accessory spans the whole bottom edge and cannot be
    /// sized, so the content is capped and centered instead of stretching edge to edge.
    private var contentMaxWidth: CGFloat { sizeClass == .regular ? 360 : .infinity }

    private var isInline: Bool { placement == .inline }

    var body: some View {
        if let ongoing {
            ongoingStrip(ongoing)
        } else {
            logStrip
        }
    }

    // MARK: Ongoing

    private func ongoingStrip(_ migraine: Migraine) -> some View {
        Button {
            onOpenOngoing(migraine.id)
        } label: {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: Brand.Space.sm) {
                    Image(systemName: "waveform.path.ecg")
                        .symbolVariant(.fill)
                        .foregroundStyle(LinearGradient.mygraHorizontal)
                        .symbolEffect(.pulse, options: reduceMotion ? .nonRepeating : .repeating)
                        .accessibilityHidden(true)
                    if !isInline {
                        Text("Ongoing")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text(MigraineDates.elapsedString(since: migraine.startDate, now: context.date))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    if !isInline {
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, isInline ? Brand.Space.sm : Brand.Space.lg)
                .frame(maxWidth: contentMaxWidth, minHeight: 32)
                // A soft brand tint so the live state reads as a distinct, tappable chip.
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("ongoingMigraineAccessory")
        .accessibilityLabel(Text("Ongoing migraine in progress, tap to view"))
    }

    // MARK: Log

    /// Just the quick action, as a filled capsule so it reads as a button. The dashboard
    /// header already says how long it has been, so the pill never repeats the status.
    /// The fill is the brand purple deepened slightly so white text clears 4.5:1 contrast
    /// in light and dark mode (the pure brand purple reaches about 4.4:1).
    private var logStrip: some View {
        Button(action: onLog) {
            Label("Log a Migraine", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(onTintedSurface ? AnyShapeStyle(.white) : AnyShapeStyle(Color.mygraPurple.mix(with: .black, by: 0.12)))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, Brand.Space.lg)
                .frame(maxWidth: contentMaxWidth, minHeight: 32)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("l", modifiers: .command)
        .hoverHighlight()
        .padding(.horizontal, isInline ? Brand.Space.xs : Brand.Space.sm)
        .accessibilityIdentifier("accessoryLogButton")
        .accessibilityLabel(Text("Log a new migraine"))
    }
}

// MARK: - Duo status strip

/// The height of the status strip on the iPhone Duo.
private let duoStripHeight: CGFloat = 52

/// The status accessory on the iPhone Duo, where the tab bar is a vertical strip on the
/// trailing edge. It is an ordinary bottom inset (which already stops short of that strip),
/// and when the device is open it stays inside the leading pane so nothing sits on the hinge.
@available(iOS 26.0, *)
private struct DuoStatusStrip: View {
    let ongoing: Migraine?
    let onOpenOngoing: (UUID) -> Void
    let onLog: () -> Void

    @State private var layout = LayoutProbe()

    var body: some View {
        Color.clear
            .frame(height: duoStripHeight)
            .overlay {
                // One capsule: the tinted glass is the control's only edge (the accessory draws
                // no fill of its own here).
                let tint = ongoing == nil ? Color.mygraPurple.mix(with: .black, by: 0.12) : Color.mygraPurple.opacity(0.5)
                let chip = MigraineStatusAccessory(ongoing: ongoing, onOpenOngoing: onOpenOngoing, onLog: onLog, onTintedSurface: true)
                if let fold = layout.foldCenterX {
                    // Open: centered in the leading pane, clear of the hinge.
                    chip
                        .frame(width: min(max(0, fold - Brand.Space.xl * 2), 360))
                        .glassEffect(.regular.tint(tint).interactive(), in: Capsule())
                        .frame(width: fold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    chip
                        .glassEffect(.regular.tint(tint).interactive(), in: Capsule())
                        .padding(.horizontal, Brand.Space.sm)
                }
            }
            .containerLayoutProbe { layout = $0 }
    }
}

// MARK: - Strip clearance

private extension View {
    /// Keeps the Duo's status strip from covering the end of a tab's scrolling content: the
    /// strip floats over the page, and the system does not inset tab content for it, so the
    /// page reserves the strip's height as a bottom safe-area inset.
    @ViewBuilder
    func duoStripClearance(isEnabled: Bool) -> some View {
        if PhoneDuo.isDuo, isEnabled {
            safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: duoStripHeight + Brand.Space.sm)
            }
        } else {
            self
        }
    }
}

// MARK: - Toolbar gating

private extension View {
    /// Adds the legacy "+" toolbar button only where the bottom accessory pill does not exist
    /// (iOS 18 to 25), so logging has exactly one entry point on every OS.
    @ContentBuilder
    func newMigraineToolbarIfNeeded(_ main: MainView) -> some View {
        if #available(iOS 26.0, *) {
            self
        } else {
            self.toolbar { main.newMigraineToolbar }
        }
    }
}

// MARK: - Navigation model

@MainActor
@Observable
final class NavigationModel {
    var showingEntrySheet = false
    var showingOngoingAlert = false
    var showingAssistant = false
    var dashboardPath = NavigationPath()
    var listPath = NavigationPath()
    var calendarPath = NavigationPath()
    var settingsPath = NavigationPath()
    var lastPushedMigraineID: UUID?
}
#endif
