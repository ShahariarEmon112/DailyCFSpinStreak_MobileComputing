//
//  TagChip.swift
//  DailyCFSpinStreak
//
//  A rounded "pill" label. Used for problem tags and small badges
//  (e.g. "Hint used", "Verified").
//

import SwiftUI

struct TagChip: View {
    let text: String
    var color: Color = Theme.info
    var isSelected: Bool = false   // filled background when selected (Spin filters)

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? Theme.background : color)
            .background(isSelected ? color : color.opacity(0.15))
            .clipShape(Capsule())
    }
}

/// Small colored badge that shows a problem rating, e.g. "1400".
struct RatingBadge: View {
    let rating: Int?

    var body: some View {
        TagChip(text: rating.map { "\($0)" } ?? "Unrated",
                color: Theme.ratingColor(rating))
            .accessibilityLabel(rating.map { "Rating \($0)" } ?? "Unrated")
    }
}

#Preview {
    HStack {
        TagChip(text: "dp")
        TagChip(text: "greedy", isSelected: true)
        RatingBadge(rating: 1400)
    }
    .padding()
    .background(Theme.background)
}
