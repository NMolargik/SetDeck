//
//  SettingsComponents.swift
//  OpaliteFeatureSettings
//
//  Internal building blocks shared by the Settings pages and sheets: the Onyx
//  status card, the showcase hero / feature / step rows used by the info sheets, a
//  yes-no status mark, and the preview environment extended with the Services managers.
//

#if os(iOS) || os(visionOS)
import SwiftUI
import OpaliteCore
import OpaliteDesignSystem
import OpaliteServices
import OpaliteFeatureShared

// MARK: - Onyx status card

/// The Onyx card: the Onyx mark, one line about the tier, and a status capsule, on the
/// flat black Onyx surface (the same in light and dark appearance).
struct OnyxStatusCard: View {
    let status: OnyxStatus
    var showsChevronGutter = false
    @Environment(\.settingsRowState) private var rowState

    static let rowCornerRadius = OnyxMetrics.listRowCornerRadius

    var body: some View {
        HStack(alignment: .top, spacing: Brand.Space.md) {
            VStack(alignment: .leading, spacing: Brand.Space.sm) {
                OnyxMark()
                Text(status.detail)
                    .font(.footnote)
                    .foregroundStyle(OnyxPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Brand.Space.sm)

            Text(status.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OnyxPalette.text)
                .padding(.horizontal, Brand.Space.md)
                .padding(.vertical, 5)
                .background(Capsule(style: .continuous).fill(OnyxPalette.raised))
                .overlay(Capsule(style: .continuous).strokeBorder(OnyxPalette.border))
                .contentTransition(.opacity)
        }
        .padding(Brand.Space.lg)
        .padding(.trailing, showsChevronGutter ? Brand.Space.lg : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onyxSurface(cornerRadius: Self.rowCornerRadius)
        .overlay(alignment: .trailing) {
            if rowState.isSplitRow {
                DisclosureChevron(color: OnyxPalette.secondaryText)
                    .padding(.trailing, Brand.Space.lg)
            }
        }
        .overlay {
            // The selection ring is part of the card: inside its bounds, on its own shape.
            if rowState.isSelected {
                RoundedRectangle(cornerRadius: Self.rowCornerRadius, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: 2.5)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(rowState.isSelected ? .isSelected : [])
        .accessibilityLabel(Text("Onyx, \(status.title). \(status.detail)"))
    }
}

// MARK: - Showcase pieces (info sheets)

/// A large glowing symbol with a title and tagline, for the top of an info sheet.
struct ShowcaseHero: View {
    let systemImage: String
    let gradient: LinearGradient
    let glow: Color
    let title: String
    let subtitle: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 76
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Brand.Space.md) {
            ZStack {
                Circle()
                    .fill(glow.opacity(0.35))
                    .frame(width: symbolSize * 1.9, height: symbolSize * 1.9)
                    .blur(radius: 28)
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: symbolSize, height: symbolSize)
                    .foregroundStyle(gradient)
                    .symbolRenderingMode(.hierarchical)
                    .shadow(color: glow.opacity(0.5), radius: 14)
                    .symbolEffect(.bounce, options: .nonRepeating, value: appeared)
            }
            .scaleEffect(appeared || reduceMotion ? 1 : 0.7)
            .opacity(appeared || reduceMotion ? 1 : 0)
            .accessibilityHidden(true)

            Text(title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Brand.Space.xl)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.8)) { appeared = true }
        }
    }
}

/// An icon-in-a-circle row with a title and a description.
struct ShowcaseFeatureRow: View {
    let systemImage: String
    let title: String
    let detail: String
    var tint: Color = .opalitePurple

    @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = 44

    var body: some View {
        HStack(alignment: .top, spacing: Brand.Space.md) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint.inkVariant)
                .frame(width: badgeSize, height: badgeSize)
                .background(Circle().fill(tint.opacity(0.14)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Brand.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

/// A numbered step in a "how it works" list.
struct ShowcaseStepRow: View {
    let number: Int
    let text: String
    var tint: Color = .opalitePurple

    @ScaledMetric(relativeTo: .caption) private var badgeSize: CGFloat = 24

    var body: some View {
        HStack(alignment: .top, spacing: Brand.Space.md) {
            Text(number.formatted())
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: badgeSize, height: badgeSize)
                .background(Circle().fill(tint))
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Step \(number): \(text)"))
    }
}

// MARK: - Status mark

/// A green check or a quiet "No" for yes/no status rows.
struct StatusMark: View {
    let isOn: Bool

    var body: some View {
        if isOn {
            Image(systemName: "checkmark.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.green)
                .accessibilityLabel(Text("Yes"))
        } else {
            Text("No")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#if DEBUG
extension View {
    /// The shared preview graph plus the Services managers Settings reads.
    func settingsPreviewEnvironment(hasOnyx: Bool = false) -> some View {
        self
            .previewEnvironment(hasOnyx: hasOnyx)
            .environment(CloudSyncManager())
            .environment(BackupManager.preview())
            .environment(SubscriptionManager())
            #if os(iOS) && canImport(WatchConnectivity)
            .environment(PhoneConnectivityManager())
            #endif
    }
}

#Preview("Onyx cards") {
    VStack(spacing: 16) {
        OnyxStatusCard(status: OnyxStatus(hasOnyx: false, subscription: nil))
        OnyxStatusCard(status: OnyxStatus(hasOnyx: true, subscription: .annual))
        OnyxStatusCard(status: OnyxStatus(hasOnyx: true, subscription: .lifetime))
    }
    .padding()
    .background(groupedBackground)
}
#endif
#endif
