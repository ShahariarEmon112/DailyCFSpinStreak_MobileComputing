//
//  ProblemViewModel.swift
//  DailyCFSpinStreak
//
//  Spin filters (rating range + tags), the spun problem, and the retry list.
//
//  STEP 2: spins from SampleData and keeps the retry list in memory.
//  STEP 4/5: problems come from the Codeforces API, retry list from Firestore.
//

import Foundation
import Combine

final class ProblemViewModel: ObservableObject {
    // Rating limits on Codeforces
    static let lowestRating = 800
    static let highestRating = 3500

    /// Tags the user can filter by. Values are the exact Codeforces tag names.
    static let availableTags = [
        "dp", "graphs", "greedy", "math", "binary search", "implementation",
        "strings", "number theory", "brute force", "constructive algorithms",
        "sortings", "data structures", "trees", "two pointers", "bitmasks", "dfs and similar",
    ]

    // MARK: Filters
    @Published var minRating = 800
    @Published var maxRating = 1400
    @Published var selectedTags: Set<String> = []

    // MARK: Spin result
    @Published var currentProblem: Problem?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: Retry list
    @Published var retryList: [Problem] = []

    // MARK: - Filters

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    /// Keeps min <= max after the user changes one of them.
    func fixRatingRange(changedMin: Bool) {
        if minRating > maxRating {
            if changedMin { maxRating = minRating } else { minRating = maxRating }
        }
    }

    /// True if the problem matches the rating range and has ALL selected tags.
    func matchesFilters(_ problem: Problem) -> Bool {
        guard let rating = problem.rating else { return false }   // skip unrated
        guard rating >= minRating && rating <= maxRating else { return false }
        return selectedTags.isSubset(of: Set(problem.tagList))
    }

    // MARK: - Spin

    func spin() {
        errorMessage = nil
        let candidates = SampleData.problems.filter { matchesFilters($0) }

        // Prefer a different problem than the one already shown.
        let fresh = candidates.filter { $0.id != currentProblem?.id }
        if let picked = (fresh.isEmpty ? candidates : fresh).randomElement() {
            currentProblem = picked
        } else {
            currentProblem = nil
            errorMessage = "No problem matches these filters. Try a wider rating range or fewer tags."
        }
    }

    // MARK: - Retry list

    func isInRetryList(_ problem: Problem) -> Bool {
        retryList.contains { $0.id == problem.id }
    }

    func addToRetryList(_ problem: Problem) {
        guard !isInRetryList(problem) else { return }   // no duplicates
        retryList.insert(problem, at: 0)
    }

    /// Called by List's swipe-to-delete (.onDelete gives us the row positions).
    func removeFromRetryList(at offsets: IndexSet) {
        retryList.remove(atOffsets: offsets)
    }
}
