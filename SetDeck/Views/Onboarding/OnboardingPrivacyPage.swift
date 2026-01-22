//
//  OnboardingPrivacyPage.swift
//  SetDeck
//
//  Created by Nick Molargik on 1/22/26.
//

import SwiftUI

struct OnboardingPrivacyPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.purpleStart)
                        .accessibilityHidden(true)

                    Text("Your Privacy Matters")
                        .font(.title.bold())

                    Text("SetDeck is designed to keep your data private and secure.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 24)

                // Privacy Features
                VStack(spacing: 0) {
                    PrivacyRow(
                        icon: "iphone",
                        iconColor: .blueStart,
                        title: "On-Device Storage",
                        description: "Your routines stays on your device and in your personal iCloud."
                    )

                    Divider().padding(.leading, 56)

                    PrivacyRow(
                        icon: "person.fill.questionmark",
                        iconColor: .orangeStart,
                        title: "No Patient Data",
                        description: "Only your personal delivery stats are tracked."
                    )

                    Divider().padding(.leading, 56)

                    PrivacyRow(
                        icon: "checkmark.shield.fill",
                        iconColor: .green,
                        title: "Your Eyes Only",
                        description: "Your health data stays solely in your possession."
                    )
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: 500)
                .padding(.horizontal, 20)

                Spacer(minLength: 120)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }
}

private struct PrivacyRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingPrivacyPage()
}
