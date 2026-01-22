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
    var animateEntrance: Bool = false

    @State private var pageSelection: Int = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Drag state for the top card
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    @State private var isDraggingHorizontally: Bool = false

    // Track cards being dismissed
    @State private var dismissedCards: Set<Int> = []

    // Deal/transition animation state
    @State private var dealtCards: Set<Int> = []
    @State private var hasCompletedInitialDeal: Bool = false
    @State private var isTransitioning: Bool = false
    @State private var displayedRoutine: SetDeckRoutine?
    @State private var previousRoutineID: UUID?

    private var exercises: [SetDeckExercise] {
        (displayedRoutine ?? routine).exercises ?? []
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
        .onChange(of: routine.uuid) { oldID, newID in
            guard oldID != newID, !isTransitioning else { return }
            transitionToNewRoutine()
        }
        .onAppear {
            displayedRoutine = routine
            previousRoutineID = routine.uuid

            if animateEntrance && !exercises.isEmpty {
                dealCardsIn()
            } else {
                // If not animating, mark deal as complete so all cards show immediately
                hasCompletedInitialDeal = true
            }
        }
    }

    // MARK: - Transition Animation

    private func transitionToNewRoutine() {
        isTransitioning = true

        // Animate current cards out (top card first, then down the stack)
        let cardsToExit = visibleCardIndices
        let exitDuration = Double(cardsToExit.count) * 0.08

        for (exitOrder, cardIndex) in cardsToExit.enumerated() {
            let delay = Double(exitOrder) * 0.08

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    _ = dealtCards.remove(cardIndex)
                }
            }
        }

        // After exit animation, switch to new routine and animate in
        DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration + 0.1) {
            // Reset state for new routine
            displayedRoutine = routine
            previousRoutineID = routine.uuid
            pageSelection = 0
            dealtCards.removeAll()
            dismissedCards.removeAll()
            hasCompletedInitialDeal = false

            // Animate new cards in
            dealCardsIn()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTransitioning = false
            }
        }
    }

    // MARK: - Deal Animation

    private func dealCardsIn() {
        let cardsToDeal = visibleCardIndices.reversed() // Deal bottom cards first
        let totalCards = cardsToDeal.count

        guard totalCards > 0 else {
            hasCompletedInitialDeal = true
            return
        }

        for (dealOrder, cardIndex) in cardsToDeal.enumerated() {
            let delay = Double(dealOrder) * 0.08 // Stagger each card by 80ms
            let isLastCard = dealOrder == totalCards - 1

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    _ = dealtCards.insert(cardIndex)
                }
                // Haptic feedback for each card dealt
                Haptics.lightImpact()

                // After the last card is dealt, mark deal as complete
                if isLastCard {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        hasCompletedInitialDeal = true
                    }
                }
            }
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
        // Card is considered dealt if: it was part of initial deal animation, OR the initial deal is complete
        let isDealt = dealtCards.contains(index) || hasCompletedInitialDeal
        let isLastCard = pageSelection >= exercises.count - 1
        let canSwipe = isTopCard && isDealt && !isTransitioning && !isLastCard

        ExerciseCardView(index: index, exercise: exercise)
            .frame(width: cardWidth)
            .contentShape(Rectangle())
            .offset(x: offsetX(for: relativeIndex, isTop: isTopCard),
                    y: isDealt ? offsetY(for: relativeIndex) : dealStartOffsetY)
            .rotationEffect(rotation(for: relativeIndex, isTop: isTopCard, isDealt: isDealt))
            .scaleEffect(isDealt ? scale(for: relativeIndex) : dealStartScale)
            .opacity(isDealt ? opacity(for: relativeIndex) : 0)
            .zIndex(Double(exercises.count - relativeIndex))
            .simultaneousGesture(canSwipe ? horizontalDragGesture : nil)
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.75), value: dragOffset)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: pageSelection)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isDealt)
    }

    // Deal animation constants
    private let dealStartOffsetY: CGFloat = 400  // Start below the screen
    private let dealStartScale: CGFloat = 0.8    // Start slightly smaller
    private let dealStartRotation: Double = -15  // Start with a tilt

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

    private func rotation(for relativeIndex: Int, isTop: Bool, isDealt: Bool = true) -> Angle {
        if !isDealt {
            // Undealt cards have a tilt
            return .degrees(dealStartRotation)
        }
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

    private var horizontalDragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)

                // Only start tracking if we haven't committed yet
                if !isDraggingHorizontally {
                    // Require predominantly horizontal movement to start
                    if horizontal > vertical && horizontal > 10 {
                        isDraggingHorizontally = true
                    }
                }

                // Only update offset if we're in horizontal drag mode
                if isDraggingHorizontally {
                    dragOffset = CGSize(width: value.translation.width, height: 0)
                    dragRotation = Double(value.translation.width) * rotationFactor
                }
            }
            .onEnded { value in
                defer {
                    isDraggingHorizontally = false
                }

                // Only process if we were dragging horizontally
                guard isDraggingHorizontally else {
                    dragOffset = .zero
                    dragRotation = 0
                    return
                }

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
            .opacity(pageSelection > 0 && !isTransitioning ? 1 : 0.4)
            .disabled(pageSelection == 0 || isTransitioning)

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
            .opacity(pageSelection > 0 && !isTransitioning ? 1 : 0.4)
            .disabled(pageSelection == 0 || isTransitioning)

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
            .opacity(pageSelection < (exercises.count - 1) && !isTransitioning ? 1 : 0.4)
            .disabled(!(pageSelection < (exercises.count - 1)) || isTransitioning)
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

    return RoutineDayDeckView(routine: SetDeckRoutine.sample(), animateEntrance: true)
        .environment(exerciseManager)
        .preferredColorScheme(.dark)
}

