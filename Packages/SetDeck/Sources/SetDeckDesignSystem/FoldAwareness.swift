//
//  FoldAwareness.swift
//  SetDeckDesignSystem
//
//  iPhone Duo's hinge and cameras are "reserved regions" (iOS 27.1). These helpers keep
//  the availability check out of feature code, like the other `…IfAvailable` helpers.
//

import SwiftUI

nonisolated public extension GeometryProxy {
    /// Whether this view's window can be divided by a hardware fold, whether or not the
    /// device is folded right now. Grids use it to prefer an even number of columns.
    var hasFoldIfAvailable: Bool {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 27.1, *) {
            return !reservedRegions(kind: .division, options: .includeInactive).isEmpty
        }
        #endif
        return false
    }

    /// The x position (in this view's own coordinate space) of a vertical hardware fold
    /// that divides this view's window, active or not; nil when there is none, or when the
    /// fold runs across the view (the open portrait pose).
    var foldCenterXIfAvailable: CGFloat? {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 27.1, *) {
            let region = reservedRegions(kind: .division, options: .includeInactive).first { $0.frame.width < $0.frame.height }
            return region?.frame.midX
        }
        #endif
        return nil
    }

    /// Whether a fold currently divides this view (the device is partially open). Layouts
    /// widen the gap between columns so nothing sits in the curve.
    var isFoldActiveIfAvailable: Bool {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 27.1, *) {
            return !reservedRegions(kind: .division).isEmpty
        }
        #endif
        return false
    }
}

/// What an adaptive layout reads from its container in one geometry pass.
nonisolated public struct LayoutProbe: Equatable, Sendable {
    public var width: CGFloat
    public var hasFold: Bool
    public var isFoldActive: Bool
    /// Where a vertical fold sits across the container (container coordinates), if any.
    public var foldCenterX: CGFloat?
    /// Whether the navigation bar is a vertical strip along the trailing edge (iPhone Duo,
    /// closed or open): a wide trailing safe area with nothing at the leading side. iPhone in
    /// landscape has both sides, so it does not match. Unlike `hasFold` this also holds when
    /// the device is closed, where the system reports no reserved region.
    public var hasVerticalBar: Bool

    public init(width: CGFloat = 0, hasFold: Bool = false, isFoldActive: Bool = false, foldCenterX: CGFloat? = nil, hasVerticalBar: Bool = false) {
        self.width = width
        self.hasFold = hasFold
        self.isFoldActive = isFoldActive
        self.foldCenterX = foldCenterX
        self.hasVerticalBar = hasVerticalBar
    }

    public init(_ proxy: GeometryProxy) {
        self.init(width: proxy.size.width, hasFold: proxy.hasFoldIfAvailable, isFoldActive: proxy.isFoldActiveIfAvailable, foldCenterX: proxy.foldCenterXIfAvailable, hasVerticalBar: Self.isVerticalBar(proxy.safeAreaInsets))
    }

    /// The vertical-bar test (see `hasVerticalBar`). Which device this is comes from
    /// `PhoneDuo.isDuo`, the one Duo check in the app; the safe-area insets are consulted only
    /// for what they alone can say: whether the bar sits inside this particular view (a column
    /// on the unfolded Duo that does not touch the bar has no such inset).
    public static func isVerticalBar(_ insets: EdgeInsets) -> Bool {
        PhoneDuo.isDuo && insets.trailing >= 60 && insets.leading <= 8
    }

    /// The gap above a detail page's first cards. A page with its own title row above the
    /// cards (palette detail) adds none on the Duo; one without (colour detail) keeps the
    /// card spacing there, because the Duo page extends under the top edge and the first
    /// cards would otherwise sit flush against it with their corners clipped. Everywhere
    /// else a small gap sits under the navigation bar.
    public static func detailTopInset(hasVerticalBar: Bool, hasTitleRow: Bool) -> CGFloat {
        guard hasVerticalBar else { return Brand.Space.sm }
        return hasTitleRow ? 0 : Brand.Space.lg
    }
}

// MARK: - iPhone Duo detection

#if os(iOS) && !targetEnvironment(macCatalyst)
import UIKit

/// THE way to ask "is this an iPhone Duo?", in either posture. The folded Duo reports a compact
/// width like any iPhone, so the size class alone cannot tell them apart. Tab/search/settings
/// logic and the detail pages (through `LayoutProbe.hasVerticalBar`) all go through this; do
/// not re-detect the Duo from safe-area insets. Insets are used only where a layout needs
/// their values or to know whether the nav bar strip touches a given view.
nonisolated public enum PhoneDuo {
    /// The Duo's hardware model identifier (the simulator reports the same one).
    private static let modelIdentifiers: Set<String> = ["iPhone19,4"]

    public static let isDuo: Bool = {
        // The model identifier already implies the phone idiom.
        modelIdentifiers.contains(currentModelIdentifier)
    }()

    private static var currentModelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulated }
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
#else
nonisolated public enum PhoneDuo {
    public static let isDuo = false
}
#endif
