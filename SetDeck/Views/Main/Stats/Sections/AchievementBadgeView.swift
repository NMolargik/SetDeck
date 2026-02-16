//
//  AchievementBadgeView.swift
//  SetDeck
//
//  Created by Nick Molargik on 2/16/26.
//

import SwiftUI

struct AchievementBadgeView: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.category.color.opacity(0.25) : Color.gray.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: achievement.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isUnlocked ? achievement.category.color : .gray)
            }

            Text(achievement.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 72)
        }
        .opacity(isUnlocked ? 1.0 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.displayName), \(isUnlocked ? "unlocked" : "locked")")
        .accessibilityHint(achievement.description)
    }
}

#Preview {
    HStack(spacing: 20) {
        AchievementBadgeView(achievement: .firstWorkout, isUnlocked: true)
        AchievementBadgeView(achievement: .monthStrong, isUnlocked: false)
        AchievementBadgeView(achievement: .fourPlates, isUnlocked: true)
    }
    .padding()
    .preferredColorScheme(.dark)
}
