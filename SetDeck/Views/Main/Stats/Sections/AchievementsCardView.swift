//
//  AchievementsCardView.swift
//  SetDeck
//
//  Created by Nick Molargik on 2/16/26.
//

import SwiftUI

struct AchievementsCardView: View {
    let unlockedAchievements: Set<String>

    private let columns = [
        GridItem(.adaptive(minimum: 72), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)

                Spacer()

                Text("\(unlockedAchievements.count)/\(Achievement.allCases.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(AchievementCategory.allCases, id: \.self) { category in
                let achievements = Achievement.achievementsInCategory(category)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundStyle(category.color)

                        Text(category.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(achievements) { achievement in
                            AchievementBadgeView(
                                achievement: achievement,
                                isUnlocked: unlockedAchievements.contains(achievement.rawValue)
                            )
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

#Preview {
    AchievementsCardView(
        unlockedAchievements: ["firstWorkout", "gettingStarted", "explorer", "onePlate", "buildingBlocks"]
    )
    .padding()
    .preferredColorScheme(.dark)
}
