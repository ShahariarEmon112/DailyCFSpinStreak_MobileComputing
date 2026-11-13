//
//  UserStats.swift
//  DailyCFSpinStreak
//
//  Numbers shown on the Dashboard and History screens.
//  Calculated from the history list — not stored separately.
//

import Foundation

nonisolated struct UserStats {
    var verifiedSolved: Int = 0      // API-verified accepted solves
    var manuallyFinished: Int = 0    // finished but not verified
    var averageSeconds: Int = 0      // average solving time of finished + verified
    var highestRating: Int? = nil    // highest rating among verified solves
    var hintSolves: Int = 0

    /// Builds the statistics from a list of history entries.
    static func from(history: [SolveHistory]) -> UserStats {
        var stats = UserStats()
        let verified = history.filter { $0.status == .verified }
        let completed = history.filter { $0.status != .attempted }

        stats.verifiedSolved = verified.count
        stats.manuallyFinished = history.filter { $0.status == .finished }.count
        stats.highestRating = verified.compactMap { $0.problem.rating }.max()
        stats.hintSolves = completed.filter { $0.hintUsed }.count

        if !completed.isEmpty {
            let total = completed.reduce(0) { $0 + $1.durationSeconds }
            stats.averageSeconds = total / completed.count
        }
        return stats
    }
}
