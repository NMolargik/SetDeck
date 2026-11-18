//
//  SettingsDestinationView.swift
//  OpaliteFeatureSettings
//
//  Resolves a `SettingsDestination` to its page. The shell registers this with
//  `.navigationDestination(for: SettingsDestination.self)`.
//

#if os(iOS) || os(visionOS)
import SwiftUI
import OpaliteCore
import OpaliteDesignSystem
import OpaliteFeatureShared

public struct SettingsDestinationView: View {
    public let destination: SettingsDestination

    public init(destination: SettingsDestination) {
        self.destination = destination
    }

    public var body: some View {
        switch destination {
        case .appearance:
            AppearanceSettingsView()
        case .accessibility:
            AccessibilitySettingsView()
        case .onyx:
            OnyxSettingsView()
        case .watch:
            #if os(iOS) && canImport(WatchConnectivity) && !targetEnvironment(macCatalyst)
            WatchSettingsView()
            #else
            WatchUnavailableView()
            #endif
        case .swatchBar:
            SwatchBarSettingsView()
        case .backups:
            BackupsView()
        case .communityAdmin:
            CommunityAdminView()
        case .about:
            AboutView()
        }
    }
}

/// Shown for `.watch` where there is no WatchConnectivity (Mac, visionOS).
struct WatchUnavailableView: View {
    var body: some View {
        EmptyStateView(
            String(localized: "Apple Watch Syncs from iPhone"),
            systemImage: "applewatch",
            description: String(localized: "Open Opalite on your iPhone to send colors and palettes to your Apple Watch.")
        )
        .navigationTitle("Apple Watch")
        .statusSubtitle()
    }
}

#if DEBUG
#Preview("Destinations") {
    NavigationStack {
        List {
            NavigationLink("Appearance", value: SettingsDestination.appearance)
            NavigationLink("Accessibility", value: SettingsDestination.accessibility)
            NavigationLink("Onyx", value: SettingsDestination.onyx)
            NavigationLink("Apple Watch", value: SettingsDestination.watch)
            NavigationLink("SwatchBar", value: SettingsDestination.swatchBar)
            NavigationLink("Backups", value: SettingsDestination.backups)
            NavigationLink("Moderation", value: SettingsDestination.communityAdmin)
            NavigationLink("About", value: SettingsDestination.about)
        }
        .navigationDestination(for: SettingsDestination.self) { SettingsDestinationView(destination: $0) }
    }
    .settingsPreviewEnvironment()
}
#endif
#endif
