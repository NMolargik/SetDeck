//
//  RoutineDayDeckView.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/14/25.
//

import SwiftUI
import SwiftData

struct RoutineDayDeckView: View {
    let routine: SetDeckRoutine
    @State private var pageSelection: Int = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Drag state for the top card
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0

    // Track cards being dismissed
    @State private var dismissedCards: Set<Int> = []

    private var exercises: [SetDeckExercise] {
        routine.exercises ?? []
    }

    // Configuration for the card stack appearance
    private let maxVisibleCards: Int = 3
    private let cardOffsetX: CGFloat = 8
    private let cardOffsetY: CGFloat = 4
    private let cardRotationDegrees: Double = 2.5
    private let swipeThreshold: CGFloat = 100
    private let rotationFactor: Double = 0.1

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ZStack {
                    if exercises.isEmpty {
                        EmptyDayCardView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        cardStack(in: proxy)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 16)
            }
            .transition(.move(edge: .leading))

            navigationBar
        }
        .onChange(of: exercises.count) { _, newCount in
            if newCount == 0 {
                pageSelection = 0
            } else if pageSelection > newCount - 1 {
                pageSelection = max(0, newCount - 1)
            }
            dismissedCards.removeAll()
        }
    }

    // MARK: - Card Stack

    @ViewBuilder
    private func cardStack(in proxy: GeometryProxy) -> some View {
        let cardWidth = min(proxy.size.width, max(280, proxy.size.width * 0.88))

        ZStack {
            // Render cards in reverse order so the current card is on top
            ForEach(visibleCardIndices.reversed(), id: \.self) { index in
                let relativeIndex = index - pageSelection

                if relativeIndex >= 0 && relativeIndex < maxVisibleCards {
                    cardView(
                        for: exercises[index],
                        at: index,
                        relativeIndex: relativeIndex,
                        cardWidth: cardWidth
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var visibleCardIndices: [Int] {
        let start = pageSelection
        let end = min(pageSelection + maxVisibleCards, exercises.count)
        return Array(start..<end)
    }

    @ViewBuilder
    private func cardView(
        for exercise: SetDeckExercise,
        at index: Int,
        relativeIndex: Int,
        cardWidth: CGFloat
    ) -> some View {
        let isTopCard = relativeIndex == 0

        ExerciseCardView(index: index, exercise: exercise)
            .frame(width: cardWidth)
            .offset(x: offsetX(for: relativeIndex, isTop: isTopCard),
                    y: offsetY(for: relativeIndex))
            .rotationEffect(rotation(for: relativeIndex, isTop: isTopCard))
            .scaleEffect(scale(for: relativeIndex))
            .opacity(opacity(for: relativeIndex))
            .zIndex(Double(exercises.count - relativeIndex))
            .gesture(isTopCard ? dragGesture : nil)
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.75), value: dragOffset)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: pageSelection)
    }

    // MARK: - Card Transformations

    private func offsetX(for relativeIndex: Int, isTop: Bool) -> CGFloat {
        if isTop {
            return dragOffset.width
        }
        // Cards behind are offset to the right with a slight stagger
        return CGFloat(relativeIndex) * cardOffsetX
    }

    private func offsetY(for relativeIndex: Int) -> CGFloat {
        // Cards behind are slightly lower
        return CGFloat(relativeIndex) * cardOffsetY
    }

    private func rotation(for relativeIndex: Int, isTop: Bool) -> Angle {
        if isTop {
            // Top card rotates based on drag
            return .degrees(dragRotation)
        }
        // Cards behind have a slight clockwise rotation
        return .degrees(Double(relativeIndex) * cardRotationDegrees)
    }

    private func scale(for relativeIndex: Int) -> CGFloat {
        // Cards behind are slightly smaller
        let scaleReduction: CGFloat = 0.03
        return 1.0 - (CGFloat(relativeIndex) * scaleReduction)
    }

    private func opacity(for relativeIndex: Int) -> Double {
        // Top card is fully opaque, cards behind are more transparent
        if relativeIndex == 0 {
            return 1.0
        }
        let opacityReduction: Double = 0.15
        return 1.0 - (Double(relativeIndex) * opacityReduction)
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                // Rotate based on horizontal drag
                dragRotation = Double(value.translation.width) * rotationFactor
            }
            .onEnded { value in
                let horizontalSwipe = abs(value.translation.width)
                let velocity = abs(value.velocity.width)

                // Check if swipe was strong enough
                if horizontalSwipe > swipeThreshold || velocity > 500 {
                    // Determine swipe direction
                    let direction: CGFloat = value.translation.width > 0 ? 1 : -1
                    dismissCard(direction: direction)
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dragOffset = .zero
                        dragRotation = 0
                    }
                }
            }
    }

    private func dismissCard(direction: CGFloat) {
        let dismissDistance: CGFloat = 500

        // Animate the card flying off
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset.width = direction * dismissDistance
            dragRotation = Double(direction) * 30
        }

        // After animation, advance to next card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if pageSelection < exercises.count - 1 {
                pageSelection += 1
            }
            // Reset drag state
            dragOffset = .zero
            dragRotation = 0

            // Haptic feedback
            Haptics.lightImpact()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 8) {
            // Reset button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    pageSelection = 0
                    dragOffset = .zero
                    dragRotation = 0
                }
                Haptics.lightImpact()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline.weight(.semibold))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .hoverEffectIfAvailable(.highlight)
            .accessibilityLabel("Go to first exercise")
            .accessibilityHint("Returns to the first exercise in the routine")
            .tint(.secondary)
            .foregroundStyle(.secondary)
            .opacity(pageSelection > 0 ? 1 : 0.4)
            .disabled(pageSelection == 0)

            // Previous button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    if pageSelection > 0 { pageSelection -= 1 }
                }
                Haptics.lightImpact()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.semibold))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .hoverEffectIfAvailable(.highlight)
            .accessibilityLabel("Previous exercise")
            .accessibilityHint("Shows the previous exercise in the routine")
            .tint(.secondary)
            .foregroundStyle(.secondary)
            .opacity(pageSelection > 0 ? 1 : 0.4)
            .disabled(pageSelection == 0)

            // Progress label
            let total = exercises.count
            let current = min(max(pageSelection + 1, 0), max(total, 1))
            if total > 0 {
                Text("\(current) of \(total)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .accessibilityLabel("Exercise \(current) of \(total)")
            }

            Spacer(minLength: 0)

            // Next button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    if pageSelection < (exercises.count - 1) { pageSelection += 1 }
                }
                Haptics.lightImpact()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.semibold))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .hoverEffectIfAvailable(.highlight)
            .accessibilityLabel("Next exercise")
            .accessibilityHint("Shows the next exercise in the routine")
            .tint(.secondary)
            .foregroundStyle(.secondary)
            .opacity(pageSelection < (exercises.count - 1) ? 1 : 0.4)
            .disabled(!(pageSelection < (exercises.count - 1)))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, horizontalSizeClass == .compact ? 20 : 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Exercise navigation")
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([SetDeckRoutine.self, SetDeckExercise.self, SetDeckSet.self, SetDeckSetHistory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    let context = ModelContext(container)
    let exerciseManager = ExerciseManager(context: context)

    // Seed one routine per weekday for previewing
    let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    for (_, _) in weekdays.enumerated() {
        let routine = SetDeckRoutine.sample()
        context.insert(routine)
    }
    try? context.save()

    return RoutineDayDeckView(routine: SetDeckRoutine.sample())
        .environment(exerciseManager)
        .preferredColorScheme(.dark)
}

