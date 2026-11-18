//
//  SettingsSplitView.swift
//  OpaliteFeatureSettings
//
//  Settings as a split view for the unfolded iPhone Duo: the existing Settings list in a
//  leading pane and the selected section's page to its right. The list and the pages are
//  the same views the pushed layout uses; only the rows' behavior changes (they select
//  instead of pushing) through the `settingsSelection` environment value.
//

#if os(iOS) || os(visionOS)
import SwiftUI
import OpaliteCore
import OpaliteDesignSystem
import OpaliteFeatureShared

private struct SettingsSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<SettingsDestination?>? = nil
}

extension EnvironmentValues {
    /// Set by `SettingsSplitView`; when present, Settings rows select a section instead of pushing it.
    var settingsSelection: Binding<SettingsDestination?>? {
        get { self[SettingsSelectionKey.self] }
        set { self[SettingsSelectionKey.self] = newValue }
    }
}

/// What a split-view Settings row tells its label: whether it is the selected row and whether
/// to draw its own disclosure chevron (the Onyx card draws it inside its black surface).
struct SettingsRowState: Equatable {
    var isSelected = false
    var isSplitRow = false
}

private struct SettingsRowStateKey: EnvironmentKey {
    static let defaultValue = SettingsRowState()
}

extension EnvironmentValues {
    var settingsRowState: SettingsRowState {
        get { self[SettingsRowStateKey.self] }
        set { self[SettingsRowStateKey.self] = newValue }
    }
}

/// A trailing disclosure chevron in the system indicator's size, weight and tertiary color.
struct DisclosureChevron: View {
    var color: Color? = nil

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(color.map(AnyShapeStyle.init) ?? AnyShapeStyle(.tertiary))
            .accessibilityHidden(true)
    }
}

/// A Settings row that pushes its page, or selects it in the split view's detail pane.
struct SettingsRowLink<Label: View>: View {
    let destination: SettingsDestination
    let label: Label
    /// For rows that clear their own background (the Onyx card): a ring marks the selection.
    var ringsWhenSelected = false
    /// For card rows: the spoken label of the whole row (the visual card is hidden from VoiceOver).
    var accessibilityLabel: Text?
    @Environment(\.settingsSelection) private var selection

    init(_ destination: SettingsDestination, ringsWhenSelected: Bool = false, accessibilityLabel: Text? = nil, @ViewBuilder label: () -> Label) {
        self.destination = destination
        self.ringsWhenSelected = ringsWhenSelected
        self.accessibilityLabel = accessibilityLabel
        self.label = label()
    }

    var body: some View {
        if let selection {
            let isSelected = selection.wrappedValue == destination
            Button {
                selection.wrappedValue = destination
            } label: {
                HStack(spacing: Brand.Space.sm) {
                    label
                        .environment(\.settingsRowState, SettingsRowState(isSelected: isSelected, isSplitRow: true))
                    if !ringsWhenSelected {
                        Spacer(minLength: 0)
                        DisclosureChevron()
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(isSelected && !ringsWhenSelected ? Color.accentColor.opacity(0.18) : nil)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else if ringsWhenSelected {
            // A card row: the system chevron would float outside the edge-to-edge card, so the
            // link is hidden behind the card (still the row's tap target) and the card draws
            // its own chevron.
            // The link is the one accessible element (it navigates, so VoiceOver's double-tap
            // works); the visual card is hidden from accessibility.
            label
                .environment(\.settingsRowState, SettingsRowState(isSelected: false, isSplitRow: true))
                .accessibilityHidden(true)
                .overlay {
                    NavigationLink(value: destination) { EmptyView() }
                        .opacity(0)
                        .accessibilityLabel(accessibilityLabel ?? Text(verbatim: ""))
                }
        } else {
            NavigationLink(value: destination) { label }
        }
    }
}

public struct SettingsSplitView: View {
    @Binding private var selection: SettingsDestination?

    public init(selection: Binding<SettingsDestination?>) {
        _selection = selection
    }

    public var body: some View {
        NavigationSplitView {
            SettingsView()
                .environment(\.settingsSelection, $selection)
                .navigationSplitViewColumnWidth(min: 320, ideal: 350, max: 400)
        } detail: {
            NavigationStack {
                if let selection {
                    SettingsDestinationView(destination: selection)
                        .id(selection)
                        .navigationDestination(for: SettingsDestination.self) { SettingsDestinationView(destination: $0) }
                } else {
                    EmptyStateView(
                        String(localized: "Choose a Setting"),
                        systemImage: "gearshape",
                        description: String(localized: "Pick a section on the left.")
                    )
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
#endif
