//
//  ProblemCard.swift
//  DailyCFSpinStreak
//
//  Card that shows a problem's name, id (contest + index) and rating.
//  Tags are only shown when `showTags` is true (hidden-hint feature).
//

import SwiftUI

struct ProblemCard: View {
    let problem: Problem
    var showTags: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(problem.id)
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                RatingBadge(rating: problem.rating)
            }

            Text(problem.name)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                Label("Contest \(problem.contestId.map(String.init) ?? "—")", systemImage: "trophy")
                Label("Index \(problem.index)", systemImage: "number")
            }
            .font(.footnote)
            .foregroundStyle(Theme.textSecondary)

            if showTags {
                if problem.tagList.isEmpty {
                    Text("No tags available for this problem.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    TagGrid(tags: problem.tagList)
                }
            }
        }
        .cardStyle()
    }
}

/// Shows tags in a grid that wraps onto new lines on small screens.
struct TagGrid: View {
    let tags: [String]

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8, alignment: .leading)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                TagChip(text: tag)
            }
        }
    }
}

#Preview {
    VStack {
        ProblemCard(problem: SampleData.problems[4])
        ProblemCard(problem: SampleData.problems[4], showTags: true)
    }
    .padding()
    .background(Theme.background)
}
