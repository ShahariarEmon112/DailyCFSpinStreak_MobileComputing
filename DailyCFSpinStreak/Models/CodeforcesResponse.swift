//
//  CodeforcesResponse.swift
//  DailyCFSpinStreak
//
//  Every Codeforces API answer has the same "envelope":
//     success: { "status": "OK",     "result": ... }
//     failure: { "status": "FAILED", "comment": "handle: User with handle xyz not found" }
//
//  CodeforcesResponse is GENERIC: `T` is the type inside "result", so one
//  struct works for problems, submissions and users.
//

import Foundation

nonisolated struct CodeforcesResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let status: String      // "OK" or "FAILED"
    let comment: String?    // reason, only when status is "FAILED"
    let result: T?          // the real data, only when status is "OK"
}

/// "result" of problemset.problems → { "problems": [...], "problemStatistics": [...] }
/// We only need "problems"; extra JSON keys are ignored by Codable.
nonisolated struct ProblemsetResult: Decodable, Sendable {
    let problems: [Problem]
}

/// One element of "result" in user.info (used to check that a handle exists).
nonisolated struct CodeforcesUser: Decodable, Sendable {
    let handle: String      // correctly capitalised handle, e.g. "tourist"
    let rating: Int?        // nil for users who never took part in a rated contest
    let rank: String?
}
