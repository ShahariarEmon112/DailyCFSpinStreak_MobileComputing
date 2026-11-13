//
//  SampleData.swift
//  DailyCFSpinStreak
//
//  TEMPORARY placeholder data so the UI can be built and tested in Step 2
//  before Firebase (Step 3) and the Codeforces API (Step 4) are connected.
//  These are real Codeforces problems, but they are NOT API responses.
//  This file is used only by SwiftUI previews once the real data arrives.
//

import Foundation

enum SampleData {
    static let problems: [Problem] = [
        Problem(contestId: 4, index: "A", name: "Watermelon", rating: 800, tags: ["brute force", "math"]),
        Problem(contestId: 71, index: "A", name: "Way Too Long Words", rating: 800, tags: ["strings"]),
        Problem(contestId: 1, index: "A", name: "Theatre Square", rating: 1000, tags: ["math"]),
        Problem(contestId: 1352, index: "C", name: "K-th Not Divisible by n", rating: 1200, tags: ["binary search", "math"]),
        Problem(contestId: 520, index: "B", name: "Two Buttons", rating: 1400, tags: ["dfs and similar", "graphs", "greedy", "math", "shortest paths"]),
        Problem(contestId: 455, index: "A", name: "Boredom", rating: 1500, tags: ["dp"]),
    ]

    static let user = AppUser(id: "preview-uid", name: "Demo Coder", email: "demo@example.com",
                              cfHandle: nil, currentStreak: 3, longestStreak: 7)

    static let history: [SolveHistory] = [
        SolveHistory(problem: problems[5], durationSeconds: 1860, hintUsed: true,
                     status: .verified, attemptedAt: .now.addingTimeInterval(-86_400), verifiedAt: .now.addingTimeInterval(-86_000)),
        SolveHistory(problem: problems[2], durationSeconds: 540, hintUsed: false,
                     status: .finished, attemptedAt: .now.addingTimeInterval(-172_800), verifiedAt: nil),
        SolveHistory(problem: problems[0], durationSeconds: 300, hintUsed: false,
                     status: .verified, attemptedAt: .now.addingTimeInterval(-259_200), verifiedAt: .now.addingTimeInterval(-259_000)),
    ]
}
