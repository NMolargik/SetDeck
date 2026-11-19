//
//  FoldSplit.swift
//  SetDeckDesignSystem
//
//  Two panes either side of a vertical fold. Narrow containers (any phone, folded Duo)
//  get the `compact` content untouched; wide ones (unfolded Duo, iPad) split in two with
//  the divide on the hinge when there is one, or at `splitFraction` of the width when not.
//

#if os(iOS)
import SwiftUI

public struct FoldSplit<Compact: View, Leading: View, Trailing: View>: View {
    private let minimumWidth: CGFloat
    private let splitFraction: CGFloat
    private let compact: Compact
    private let leading: Leading
    private let trailing: Trailing

    /// - Parameters:
    ///   - minimumWidth: containers narrower than this show `compact`.
    ///   - splitFraction: where the divide falls when no hinge is present (0.5 = halves).
    public init(
        minimumWidth: CGFloat = 600,
        splitFraction: CGFloat = 0.5,
        @ViewBuilder compact: () -> Compact,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.minimumWidth = minimumWidth
        self.splitFraction = splitFraction
        self.compact = compact()
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        GeometryReader { proxy in
            if proxy.size.width < minimumWidth {
                compact
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                let probe = LayoutProbe(proxy)
                // Keep content out of the curve when the device is partially open.
                let gap = probe.isFoldActive ? Brand.Space.xxl * 2 : Brand.Space.lg
                let center = probe.foldCenterX ?? proxy.size.width * splitFraction
                let leadingWidth = max(center - gap / 2, 0)
                let trailingWidth = max(proxy.size.width - center - gap / 2, 0)
                HStack(spacing: 0) {
                    leading
                        .frame(width: leadingWidth, height: proxy.size.height)
                    Color.clear
                        .frame(width: gap, height: proxy.size.height)
                    trailing
                        .frame(width: trailingWidth, height: proxy.size.height)
                }
            }
        }
    }
}

#endif
