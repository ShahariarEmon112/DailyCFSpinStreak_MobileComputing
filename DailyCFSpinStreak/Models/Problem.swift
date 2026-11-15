//
//  Problem.swift
//  DailyCFSpinStreak
//
//  One Codeforces problem. The property names match the Codeforces API JSON
//  exactly, so `Codable` can decode it automatically (Step 4).
//  The same struct is also saved to Firestore (retry list, history).
//
//  Example JSON from https://codeforces.com/api/problemset.problems :
//  { "contestId": 4, "index": "A", "name": "Watermelon",
//    "type": "PROGRAMMING", "rating": 800, "tags": ["brute force", "math"] }
//

import Foundation

nonisolated struct Problem: Codable, Identifiable, Hashable, Sendable {
    let contestId: Int?      // optional: a few problems have no contest id
    let index: String        // "A", "B", "C1"...
    let name: String
    let rating: Int?         // optional: new / special problems may be unrated
    let tags: [String]?      // optional: be safe if the API omits tags

    /// Unique id such as "4A". Also used as the Firestore document id,
    /// which automatically prevents saving the same problem twice.
    var id: String { "\(contestId ?? 0)\(index)" }

    /// Never nil — easier to use in views than the optional `tags`.
    var tagList: [String] { tags ?? [] }

    /// Link to the original problem page on codeforces.com
    var url: URL? {
        guard let contestId else { return nil }
        return URL(string: "https://codeforces.com/problemset/problem/\(contestId)/\(index)")
    }
}

// Note on `nonisolated`: this project's build setting makes every type run on
// the MainActor by default. Data models are plain values, so we mark them
// `nonisolated` — that lets JSON / Firestore decoding use them on any thread.
