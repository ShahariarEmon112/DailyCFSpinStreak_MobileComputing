//
//  SolveHistory.swift
//  DailyCFSpinStreak
//
//  One attempt at a problem. Stored in Firestore at users/{uid}/history/{problemId}.
//

import Foundation

/// How far the user got with a problem.
nonisolated enum SolveStatus: String, Codable {
    case attempted   // started the timer but did not finish
    case finished    // pressed "Finish" manually — NOT counted for the streak
    case verified    // accepted submission found on Codeforces — counts for the streak

    var title: String {
        switch self {
        case .attempted: return "Attempted"
        case .finished:  return "Finished (manual)"
        case .verified:  return "Verified AC"
        }
    }
}

nonisolated struct SolveHistory: Codable, Identifiable {
    var id: String { problem.id }   // same id as the problem → no duplicates
    var problem: Problem
    var durationSeconds: Int
    var hintUsed: Bool
    var status: SolveStatus
    var attemptedAt: Date
    var verifiedAt: Date?           // time of the accepted submission (from Codeforces)
}
