//
//  OnboardingBuilderPage.swift
//  SetDeckFeatureOnboarding
//
//  The routine-builder step. Embeds `EditRoutineView` unchanged under a compact header; it
//  gets the full window width so the editor can use its own two-pane layout on iPad and the
//  unfolded iPhone Duo.
//

#if os(iOS)
import SwiftUI
import SetDeckDesignSystem
import SetDeckFeatureRoutine

struct OnboardingBuilderPage: View {
    var body: some View {
        VStack(spacing: Brand.Space.sm) {
            OnboardingHero(content: OnboardingContent.hero(for: .builder), showsTile: false)
                .padding(.horizontal, Brand.Space.xl)
                .frame(maxWidth: OnboardingMetrics.columnWidth)

            EditRoutineView()
                .padding(.horizontal, Brand.Space.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Keep the scrolling editor from running flush into the action bar.
                .padding(.bottom, Brand.Space.md)
        }
        .padding(.top, Brand.Space.sm)
    }
}
#endif
