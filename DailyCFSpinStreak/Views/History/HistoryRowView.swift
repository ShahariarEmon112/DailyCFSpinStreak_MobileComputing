//
//  HistoryRowView.swift
//  DailyCFSpinStreak
//
//  One row in the History list: name, rating, tags, duration, date,
//  hint usage and whether it was verified on Codeforces.
//

import SwiftUI

struct HistoryRowView: View {
    let entry: SolveHistory

    private var statusColor: Color {
        switch entry.status {
        case .verified:  return Theme.primary
        case .finished:  return Theme.info
        case .attempted: return Theme.textSecondary
        }
    }

    private var statusIcon: String {
        switch entry.status {
        case .verified:  return "checkmark.seal.fill"
        case .finished:  return "flag.checkered"
        case .attempted: return "hourglass"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.problem.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                RatingBadge(rating: entry.problem.rating)
            }

            Text(entry.problem.tagList.isEmpty ? "No tags" : entry.problem.tagList.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)

            HStack(spacing: 12) {
                Label(DisplayFormat.duration(entry.durationSeconds), systemImage: "timer")
                Label(DisplayFormat.shortDate(entry.verifiedAt ?? entry.attemptedAt), systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 8) {
                Label(entry.status.title, systemImage: statusIcon)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(statusColor)
                    .background(statusColor.opacity(0.15))
                    .clipShape(Capsule())
                if entry.hintUsed {
                    TagChip(text: "Hint used", color: Theme.streak)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        ForEach(SampleData.history) { HistoryRowView(entry: $0) }
            .listRowBackground(Theme.card)
    }
    .scrollContentBackground(.hidden)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
