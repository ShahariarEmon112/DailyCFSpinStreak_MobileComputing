//
//  Submission.swift
//  DailyCFSpinStreak
//
//  One submission from https://codeforces.com/api/user.status?handle=HANDLE
//
//  Example JSON (shortened):
//  { "id": 123456789, "contestId": 4, "creationTimeSeconds": 1731490000,
//    "problem": { "contestId": 4, "index": "A", "name": "Watermelon", ... },
//    "verdict": "OK" }
//

import Foundation

nonisolated struct Submission: Decodable, Identifiable, Sendable {
    let id: Int
    let contestId: Int?
    let creationTimeSeconds: Int    // Unix time (seconds since 1 Jan 1970, UTC)
    let problem: Problem
    let verdict: String?            // "OK" = Accepted. Missing while still being judged.

    /// Only "OK" means Accepted. WRONG_ANSWER, TIME_LIMIT_EXCEEDED, etc. do not count.
    var isAccepted: Bool { verdict == "OK" }

    /// When the submission was made, as a Date (converted to local time when displayed).
    var submittedAt: Date {
        Date(timeIntervalSince1970: TimeInterval(creationTimeSeconds))
    }
}
