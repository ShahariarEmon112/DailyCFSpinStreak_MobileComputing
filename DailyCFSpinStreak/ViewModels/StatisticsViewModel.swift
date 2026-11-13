//
//  StatisticsViewModel.swift
//  DailyCFSpinStreak
//
//  Solve history and the statistics calculated from it.
//
//  STEP 2: history is kept in memory only.
//  STEP 5: history is loaded from / saved to Firestore.
//  STEP 6: verification + streak calculation are added here.
//

import Foundation
import Combine

final class StatisticsViewModel: ObservableObject {
    @Published var history: [SolveHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Recalculated whenever `history` changes (computed property).
    var stats: UserStats { UserStats.from(history: history) }

    /// True if there is a verified solve whose accepted submission is from today.
    var solvedToday: Bool {
        history.contains { entry in
            guard entry.status == .verified, let date = entry.verifiedAt else { return false }
            return Calendar.current.isDateInToday(date)
        }
    }

    /// Problems attempted today (any status) — shown as "today's progress".
    var attemptedTodayCount: Int {
        history.filter { Calendar.current.isDateInToday($0.attemptedAt) }.count
    }

    /// Saves a manual "Finish". This NEVER changes the verified streak.
    func recordFinished(problem: Problem, durationSeconds: Int, hintUsed: Bool) {
        let entry = SolveHistory(problem: problem,
                                 durationSeconds: durationSeconds,
                                 hintUsed: hintUsed,
                                 status: .finished,
                                 attemptedAt: Date(),
                                 verifiedAt: nil)
        // Replace the old entry for the same problem, keep newest first.
        history.removeAll { $0.id == problem.id }
        history.insert(entry, at: 0)
    }
}
