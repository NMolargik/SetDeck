//
//  SettingsSplitView.swift
//  SetDeckFeatureSettings
//
//  Settings the way iPhone's Settings works in a split view: a leading list of pages, the
//  selected page to the right. On the unfolded iPhone Duo the divide sits on the hinge; on
//  iPad it is simply halved. Compact widths (any phone, folded Duo) keep the pushed list.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared

/// The pages of Settings. `SettingsView(page:)` renders one; the split view lists them all.
public enum SettingsPage: Hashable, CaseIterable, Identifiable {
    case preferences
    case about
    case achievements
    case data
    #if DEBUG
    case debug
    #endif

    public var id: Self { self }

    #if DEBUG
    /// Screenshot affordance: `-sdSettingsPage preferences|about|achievements|data|debug`.
    static var debugLaunchPage: SettingsPage? {
        switch DebugLaunch.value("-sdSettingsPage") {
        case "preferences": .preferences
        case "about": .about
        case "achievements": .achievements
        case "data": .data
        case "debug": DebugLaunch.isUITesting ? nil : .debug
        default: nil
        }
    }
    #endif

    /// Pages shown in the list. Debug is hidden under `-uiTesting` so screenshots stay clean.
    static var visible: [SettingsPage] {
        #if DEBUG
        allCases.filter { $0 != .debug || !DebugLaunch.isUITesting }
        #else
        allCases
        #endif
    }

    var title: LocalizedStringKey {
        switch self {
        case .preferences: "Preferences"
        case .about: "About"
        case .achievements: "Achievements"
        case .data: "Data"
        #if DEBUG
        case .debug: "Debug"
        #endif
        }
    }

    var systemImage: String {
        switch self {
        case .preferences: "slider.horizontal.3"
        case .about: "info.circle.fill"
        case .achievements: "trophy.fill"
        case .data: "externaldrive.fill"
        #if DEBUG
        case .debug: "wand.and.stars"
        #endif
        }
    }

    var tint: Color {
        switch self {
        case .preferences: .blueStart
        case .about: .greenStart
        case .achievements: .orange
        case .data: .red
        #if DEBUG
        case .debug: .purple
        #endif
        }
    }
}

public struct SettingsSplitView: View {
    @Environment(AchievementModel.self) private var achievementManager
    @State private var selection: SettingsPage? = .preferences
    #if DEBUG
    /// Compact layout: the page `-sdSettingsPage` asked for is pushed onto the stack.
    @State private var compactPath: [SettingsPage] = []
    #endif

    public init() {
        #if DEBUG
        if let page = SettingsPage.debugLaunchPage {
            _selection = State(initialValue: page)
            _compactPath = State(initialValue: [page])
        }
        #endif
    }

    public var body: some View {
        FoldSplit(
            compact: {
                compactStack
            },
            leading: {
                NavigationStack {
                    pageList
                        .navigationTitle("Settings")
                        .containerBackground(.clear, for: .navigation)
                }
            },
            trailing: {
                NavigationStack {
                    detail
                        .containerBackground(.clear, for: .navigation)
                }
            }
        )
        .background(BrandBackground(tint: .purpleStart))
    }

    @ViewBuilder
    private var compactStack: some View {
        #if DEBUG
        NavigationStack(path: $compactPath) {
            SettingsView()
                .navigationTitle("Settings")
                .navigationDestination(for: SettingsPage.self) { page in
                    if page == .achievements {
                        AchievementsView(unlockedAchievements: achievementManager.unlockedAchievements, showsDone: false)
                    } else {
                        SettingsView(page: page)
                            .navigationTitle(page.title)
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
        }
        #else
        NavigationStack {
            SettingsView()
                .navigationTitle("Settings")
        }
        #endif
    }

    private var pageList: some View {
        List {
            ForEach(SettingsPage.visible) { page in
                let isSelected = selection == page
                Button {
                    Haptics.lightImpact()
                    selection = page
                } label: {
                    HStack(spacing: Brand.Space.md) {
                        Image(systemName: page.systemImage)
                            .foregroundStyle(page.tint)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text(page.title)
                            .foregroundStyle(.primary)
                        Spacer(minLength: 0)
                        if page == .achievements {
                            Text("\(achievementManager.unlockedAchievements.count)/\(Achievement.allCases.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(isSelected ? Color.greenStart.opacity(0.18) : nil)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .hoverEffectIfAvailable(.highlight)
            }
        }
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var detail: some View {
        if let selection {
            Group {
                if selection == .achievements {
                    AchievementsView(unlockedAchievements: achievementManager.unlockedAchievements, showsDone: false)
                } else {
                    SettingsView(page: selection)
                        .navigationTitle(selection.title)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .id(selection)
        } else {
            ContentUnavailableView("Choose a Setting", systemImage: "gearshape", description: Text("Pick a page on the left."))
        }
    }
}
#endif
