//
//  ExerciseCardView.swift
//  SetDeckFeatureRoutine
//
//  Created by Nick Molargik on 11/14/25.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckFeatureShared
import SetDeckServices

struct ExerciseCardView: View {
    @Environment(WorkoutDataModel.self) private var exerciseManager: WorkoutDataModel
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false

    @State private var expandedSetID: UUID? = nil
    @State private var contentHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    @Environment(\.openURL) private var openURLAction
    let index: Int
    let exercise: SetDeckExercise
    /// Fallback "suit" accent, used when the exercise has no muscle group.
    var accent: Color = .greenStart
    /// Tallest the card may grow; taller content scrolls inside the card.
    var maxHeight: CGFloat = .infinity
    /// Cards behind the top card borrow the top card's height so the stack stays tidy.
    var matchedHeight: CGFloat? = nil
    /// Reports the card's natural height (top card only).
    var onHeightChange: ((CGFloat) -> Void)? = nil

    private var orderedSets: [SetDeckSet] {
        // Prefer manager fetch for consistent ordering; fallback to relationship if needed
        let fetched = exerciseManager.sets(for: exercise)
        if !fetched.isEmpty { return fetched }
        return (exercise.sets ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    /// The exercise's own muscle groups, else a best guess from its name.
    private var muscleGroups: [MuscleGroup] { exercise.presentationGroups }
    private var tint: Color { exercise.presentationTint(fallback: accent) }
    private var icon: String { exercise.presentationIcon }

    private func isLogged(_ set: SetDeckSet) -> Bool {
        (set.history ?? []).contains { Calendar.current.isDateInToday($0.completedDate) }
    }

    private var subtitle: String {
        let count = orderedSets.count
        let setText = count == 0
            ? String(localized: "No sets yet")
            : (count == 1 ? String(localized: "1 set") : String(localized: "\(count) sets"))
        guard !muscleGroups.isEmpty else { return setText }
        let names = muscleGroups.prefix(3).map(\.displayName).joined(separator: ", ")
        return "\(setText) · \(names)"
    }

    /// Set rows are at least this tall and grow to share the card's spare height, up to a cap.
    private static let minRowHeight: CGFloat = 64
    private static let maxRowHeight: CGFloat = 300

    /// Height the card may use: the deck's limit, or the (smaller) height the top card settled on.
    private var availableHeight: CGFloat {
        guard maxHeight.isFinite else { return maxHeight }
        if let matchedHeight { return min(matchedHeight, maxHeight) }
        return maxHeight
    }

    /// Everything in the card except the set rows themselves.
    private func chromeHeight(setCount: Int, allLogged: Bool) -> CGFloat {
        Brand.Space.xl * 2 + headerHeight + Brand.Space.lg
            + Brand.Space.sm * CGFloat(max(setCount - 1, 0)) + (allLogged ? 40 : 0)
    }

    /// Raw per-row share of the available height (uncapped).
    private func rowShare(setCount: Int, allLogged: Bool) -> CGFloat {
        (availableHeight - chromeHeight(setCount: setCount, allLogged: allLogged)) / CGFloat(setCount)
    }

    /// Height for each collapsed set row so the rows together fill the card.
    private func rowHeight(setCount: Int, allLogged: Bool) -> CGFloat {
        guard maxHeight.isFinite, setCount > 0, headerHeight > 0 else { return Self.minRowHeight }
        let share = rowShare(setCount: setCount, allLogged: allLogged)
        return min(max(share, Self.minRowHeight), Self.maxRowHeight)
    }

    /// The card fills the deck's height until every row has hit the cap; after that it
    /// shrinks to its content (and the deck centres it) rather than leaving an empty band.
    private func cardHeight(setCount: Int, allLogged: Bool) -> CGFloat? {
        if maxHeight.isFinite {
            guard setCount > 0, headerHeight > 0,
                  rowShare(setCount: setCount, allLogged: allLogged) > Self.maxRowHeight
            else { return availableHeight }
            let fit = chromeHeight(setCount: setCount, allLogged: allLogged)
                + Self.maxRowHeight * CGFloat(setCount)
            // An expanded row makes the content taller than the capped rows: let the card follow.
            return min(max(fit, contentHeight), availableHeight)
        }
        if let matchedHeight { return matchedHeight }
        guard contentHeight > 0 else { return nil }
        return min(contentHeight, maxHeight)
    }

    var body: some View {
        let _ = exerciseManager.changeStamp
        let sets = orderedSets
        let nextID = sets.first(where: { !isLogged($0) })?.uuid
        let allLogged = !sets.isEmpty && nextID == nil
        // While a row is open, the others drop to their minimum so the open row gets the room.
        let rowHeight = expandedSetID == nil
            ? rowHeight(setCount: sets.count, allLogged: allLogged)
            : Self.minRowHeight

        ZStack(alignment: .topLeading) {
            cardBase

            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Brand.Space.lg) {
                    header
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }

                    if sets.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: Brand.Space.sm) {
                            ForEach(sets, id: \.uuid) { set in
                                let isExpanded = Binding<Bool>(
                                    get: { expandedSetID == set.uuid },
                                    set: { newValue in
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                            expandedSetID = newValue ? set.uuid : nil
                                        }
                                    }
                                )
                                SetRowView(
                                    isEditing: isExpanded,
                                    set: set,
                                    isNext: set.uuid == nextID,
                                    isLogged: isLogged(set),
                                    accent: tint,
                                    minRowHeight: rowHeight
                                )
                            }
                        }
                        if allLogged {
                            Label("All sets logged", systemImage: "checkmark.seal.fill")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.greenStart)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(Brand.Space.xl)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    contentHeight = height
                    onHeightChange?(height)
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .scrollDisabled(matchedHeight != nil)
            .onChange(of: expandedSetID) { _, newID in
                // An open row can be taller than the card: bring it fully into the scroll view.
                guard let newID else { return }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(320))
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newID, anchor: .top)
                    }
                }
            }
            }
        }
        .frame(height: cardHeight(setCount: sets.count, allLogged: allLogged), alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(exercise.name), exercise \(index + 1)")
    }

    // MARK: - Card surface

    private var cardBase: some View {
        RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
            .fill(LinearGradient(colors: [Color(white: 0.16), Color(white: 0.10)], startPoint: .top, endPoint: .bottom))
            .overlay( // soft muscle-group wash from the top
                RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                    .fill(LinearGradient(colors: [tint.opacity(0.22), .clear], startPoint: .top, endPoint: .center))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [tint.opacity(0.55), Color.white.opacity(0.10)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 10)
    }

    private var emptyState: some View {
        VStack(spacing: Brand.Space.sm) {
            Image(systemName: "plus.rectangle.on.rectangle")
                .font(.title2)
                .foregroundStyle(tint)
                .symbolEffect(.pulse)
            Text("No sets yet")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Brand.Space.xl)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Brand.Space.md) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: Brand.Radius.chip, style: .continuous)
                        .fill(LinearGradient(colors: [tint, tint.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .shadow(color: tint.opacity(0.4), radius: 8, y: 3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name.isEmpty ? "Exercise" : exercise.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                let hasVideo = exercise.videoURL.map { !$0.absoluteString.isEmpty } ?? false
                let hasEquipment = !(exercise.equipment ?? "").isEmpty
                if exercise.isWarmup || hasEquipment || hasVideo {
                    HStack(spacing: Brand.Space.sm) {
                        if exercise.isWarmup {
                            cardPill(String(localized: "Warm-up"), systemImage: "flame.fill", tint: .orangeStart)
                        }
                        if let equipment = exercise.equipment, !equipment.isEmpty {
                            cardPill(equipment, systemImage: "scalemass.fill", tint: .secondary)
                        }
                        if let urlString = exercise.videoURL, let url = URL(string: urlString.absoluteString), !urlString.absoluteString.isEmpty {
                            Link(destination: url) {
                                cardPill(String(localized: "Video"), systemImage: "play.fill", tint: .red, filled: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func cardPill(_ title: String, systemImage: String, tint: Color, filled: Bool = false) -> some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(filled ? .white : tint)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(filled ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.14)))
            )
    }
}
#endif
