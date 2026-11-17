//
//  SampleData.swift
//  DailyCFSpinStreak
//
//  Placeholder data used ONLY by SwiftUI #Preview blocks (the Xcode canvas).
//  The running app never uses it: problems come from the Codeforces API and
//  user data from Firestore. These are real Codeforces problems, typed by hand.
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

    /// Solved today, yesterday and the day before → current streak 3.
    static let user = AppUser(id: "preview-uid", name: "Demo Coder", email: "demo@example.com",
                              cfHandle: "demo_handle", currentStreak: 3, longestStreak: 7,
                              verifiedDays: [-2, -1, 0].map { daysAgo in
                                  StreakService.dayKey(for: Date().addingTimeInterval(Double(daysAgo) * 86_400))
                              })

    static let history: [SolveHistory] = [
        SolveHistory(problem: problems[5], durationSeconds: 1860, hintUsed: true,
                     status: .verified, attemptedAt: .now.addingTimeInterval(-86_400), verifiedAt: .now.addingTimeInterval(-86_000)),
        SolveHistory(problem: problems[2], durationSeconds: 540, hintUsed: false,
                     status: .finished, attemptedAt: .now.addingTimeInterval(-172_800), verifiedAt: nil),
        SolveHistory(problem: problems[0], durationSeconds: 300, hintUsed: false,
                     status: .verified, attemptedAt: .now.addingTimeInterval(-259_200), verifiedAt: .now.addingTimeInterval(-259_000)),
    ]
}
