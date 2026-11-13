//
//  StatCard.swift
//  DailyCFSpinStreak
//
//  Small reusable card that shows one number with a label and icon.
//  Used on the Dashboard and the History statistics section.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    var color: Color = Theme.info

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)
                .accessibilityHidden(true)

            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    StatCard(title: "Total Solved", value: "12", systemImage: "checkmark.seal.fill", color: Theme.primary)
        .padding()
        .background(Theme.background)
}
