//
//  WorkoutSummaryCardView.swift
//  SetDeckFeatureHealth
//
//  Branded card for a finished workout: shown in the completion sheet and rendered to an
//  image (via `ImageRenderer`) for the share sheet.
//

#if os(iOS)
import SwiftUI
import SetDeckCore
import SetDeckDesignSystem
import SetDeckServices

struct WorkoutSummaryCardView: View {
    let summary: WorkoutSummary

    private var dateString: String {
        summary.startDate.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(.greenEnd.gradient))
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(dateString)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
            }

            HStack(spacing: 12) {
                statTile(title: "Duration", value: summary.durationString, systemImage: "timer")
                if let kcal = summary.totalEnergyBurnedKCal {
                    statTile(title: "Calories", value: "\(Int(kcal))", systemImage: "flame.fill")
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "dumbbell.fill")
                Text("SetDeck")
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(20)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.08, green: 0.10, blue: 0.12), Color(red: 0.02, green: 0.03, blue: 0.04)], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.greenStart.opacity(0.6), lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.title), \(dateString), duration \(summary.durationString)")
    }

    @ViewBuilder
    private func statTile(title: LocalizedStringKey, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.08)))
    }
}

/// `ShareLink` that renders `WorkoutSummaryCardView` to a PNG with `ImageRenderer`.
/// Appears once the render finishes (synchronously on first appearance).
public struct WorkoutSummaryShareLink: View {
    let summary: WorkoutSummary
    @State private var rendered: Image?

    public init(summary: WorkoutSummary) {
        self.summary = summary
    }

    public var body: some View {
        Group {
            if let rendered {
                ShareLink(
                    item: rendered,
                    subject: Text("Workout Summary"),
                    message: Text(shareMessage),
                    preview: SharePreview(summary.title, image: rendered)
                ) {
                    Label("Share Summary", systemImage: "square.and.arrow.up")
                }
            }
        }
        .onAppear(perform: render)
    }

    private var shareMessage: String { Self.message(for: summary) }

    /// The share text: one summary line, then the tracked link back to SetDeck.
    static func message(for summary: WorkoutSummary) -> String {
        let line: String
        if let kcal = summary.totalEnergyBurnedKCal {
            line = "\(summary.title) · \(summary.durationString) · \(Int(kcal)) cal"
        } else {
            line = "\(summary.title) · \(summary.durationString)"
        }
        return "\(line)\n\(AppLinks.shareSummary.absoluteString)"
    }

    private func render() {
        guard rendered == nil else { return }
        let renderer = ImageRenderer(content: WorkoutSummaryCardView(summary: summary).colorScheme(.dark))
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            rendered = Image(uiImage: uiImage)
        }
    }
}
#endif
