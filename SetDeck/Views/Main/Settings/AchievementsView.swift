//
//  AchievementsView.swift
//  SetDeck
//
//  Created by Nick Molargik on 2/16/26.
//

import SwiftUI

struct AchievementsView: View {
    let unlockedAchievements: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress header
                progressHeader

                // Category sections
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    categorySection(category)
                }
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .bold()
                .tint(.greenStart)
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 12) {
            let total = Achievement.allCases.count
            let unlocked = unlockedAchievements.count
            let progress = total > 0 ? Double(unlocked) / Double(total) : 0

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.greenStart, .blueStart],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(unlocked)")
                        .font(.title.bold())
                    Text("of \(total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(unlocked == total ? "All achievements unlocked!" : "Keep going!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Category Section

    @ContentBuilder
    private func categorySection(_ category: AchievementCategory) -> some View {
        let achievements = Achievement.achievementsInCategory(category)
        let unlockedInCategory = achievements.filter { unlockedAchievements.contains($0.rawValue) }.count

        VStack(alignment: .leading, spacing: 12) {
            // Category header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                    .foregroundStyle(category.color)

                Text(category.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(unlockedInCategory)/\(achievements.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Achievement rows
            ForEach(achievements) { achievement in
                let isUnlocked = unlockedAchievements.contains(achievement.rawValue)
                achievementRow(achievement, isUnlocked: isUnlocked)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
        )
    }

    // MARK: - Achievement Row

    @ContentBuilder
    private func achievementRow(_ achievement: Achievement, isUnlocked: Bool) -> some View {
        HStack(spacing: 14) {
            // Icon badge
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.category.color.opacity(0.25) : Color.gray.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: isUnlocked ? achievement.icon : "lock.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(isUnlocked ? achievement.category.color : .gray.opacity(0.5))
            }

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)

                Text(isUnlocked ? achievement.description : achievementHint(achievement))
                    .font(.caption)
                    .foregroundStyle(isUnlocked ? .secondary : .tertiary)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(achievement.category.color)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
        .opacity(isUnlocked ? 1.0 : 0.7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.displayName), \(isUnlocked ? "unlocked" : "locked")")
        .accessibilityHint(isUnlocked ? achievement.description : achievementHint(achievement))
    }

    // MARK: - Hints for locked achievements

    private func achievementHint(_ achievement: Achievement) -> String {
        switch achievement.category {
        case .consistency:
            return "Keep showing up consistently"
        case .volume:
            return "Log more sets to unlock"
        case .routine:
            return "Build out your weekly routine"
        case .variety:
            return "Try different exercises"
        case .strength:
            return "Push heavier weight"
        }
    }
}

#Preview {
    NavigationStack {
        AchievementsView(
            unlockedAchievements: ["firstWorkout", "gettingStarted", "explorer", "onePlate", "buildingBlocks"]
        )
    }
    .preferredColorScheme(.dark)
}
