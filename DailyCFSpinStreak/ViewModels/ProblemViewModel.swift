//
//  ProblemViewModel.swift
//  DailyCFSpinStreak
//
//  Spin filters (rating range + tags), the spun problem, and the retry list.
//  Problems come from the Codeforces API (CodeforcesAPIService),
//  the retry list is stored in Firestore (FirebaseService).
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
    /// Non-error note shown under the result (e.g. "this one may repeat").
    @Published var infoMessage: String?
    /// How many problems were downloaded from Codeforces (0 = not loaded yet).
    @Published private(set) var loadedProblemCount = 0

    /// Problem ids the user already got Accepted on Codeforces (never spun again).
    @Published private(set) var solvedOnCodeforces: Set<String> = []

    // MARK: Retry list
    @Published var retryList: [Problem] = []

    private let api = CodeforcesAPIService.shared
    private let firebase = FirebaseService.shared

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
        guard let rating = problem.rating else { return false }   // skip unrated problems
        guard rating >= minRating && rating <= maxRating else { return false }
        return selectedTags.isSubset(of: Set(problem.tagList))
    }

    // MARK: - Spin

    /// Picks a random problem that matches the filters.
    /// - Parameter seenProblemIds: problems already in the user's history (avoid repeats).
    func spin(seenProblemIds: Set<String>) async {
        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        // 1. Download the problem set (only the first time; then it is cached).
        let allProblems: [Problem]
        do {
            allProblems = try await api.fetchProblems()
            loadedProblemCount = allProblems.count
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        // 2. Keep only problems that match the rating range and tags.
        let candidates = allProblems.filter { matchesFilters($0) }
        if candidates.isEmpty {
            currentProblem = nil
            errorMessage = "No problem matches these filters. Try a wider rating range or fewer topics."
            return
        }

        // 3. Prefer problems the user has never seen or solved.
        let fresh = candidates.filter { problem in
            !seenProblemIds.contains(problem.id)
                && !solvedOnCodeforces.contains(problem.id)
                && problem.id != currentProblem?.id
        }

        if let picked = fresh.randomElement() {
            currentProblem = picked
        } else {
            // Everything was already seen: allow a repeat rather than showing nothing.
            currentProblem = candidates.randomElement()
            infoMessage = "You have already seen every problem with these filters, so this one may be a repeat."
        }
    }

    /// Downloads the user's submissions and remembers which problems are already
    /// Accepted, so Spin does not recommend them. Failing here is not critical.
    func loadSolvedProblems(handle: String?) async {
        guard let handle, !handle.isEmpty else {
            solvedOnCodeforces = []
            return
        }
        do {
            let submissions = try await api.fetchSubmissions(handle: handle)
            solvedOnCodeforces = Set(submissions.filter { $0.isAccepted }.map { $0.problem.id })
        } catch {
            // Keep the old set; Spin still works without it.
            print("Could not load solved problems: \(error.localizedDescription)")
        }
    }

    // MARK: - Retry list

    /// READ the saved problems from Firestore (called when the tabs appear).
    func loadRetryList() async {
        guard let uid = firebase.currentUserId else { return }
        do {
            retryList = try await firebase.fetchRetryList(uid: uid)
        } catch {
            errorMessage = "Could not load your retry list: \(error.localizedDescription)"
        }
    }

    func isInRetryList(_ problem: Problem) -> Bool {
        retryList.contains { $0.id == problem.id }
    }

    /// CREATE: saves a problem for later.
    func addToRetryList(_ problem: Problem) async {
        guard !isInRetryList(problem), let uid = firebase.currentUserId else { return }   // no duplicates
        do {
            try await firebase.addToRetryList(uid: uid, problem: problem)
            retryList.insert(problem, at: 0)
        } catch {
            errorMessage = "Could not save the problem: \(error.localizedDescription)"
        }
    }

    /// DELETE: called by List's swipe-to-delete (.onDelete gives us the row positions).
    /// The row disappears immediately; Firestore is updated in the background.
    func removeFromRetryList(at offsets: IndexSet) {
        let removed = offsets.map { retryList[$0] }
        let removedIds = Set(removed.map { $0.id })
        retryList.removeAll { removedIds.contains($0.id) }

        guard let uid = firebase.currentUserId else { return }
        Task {
            for problem in removed {
                do {
                    try await firebase.removeFromRetryList(uid: uid, problemId: problem.id)
                } catch {
                    errorMessage = "Could not delete \(problem.name): \(error.localizedDescription)"
                }
            }
        }
    }

    /// DELETE one problem (used after it gets verified as solved).
    func removeSolvedProblem(_ problem: Problem) async {
        guard let index = retryList.firstIndex(where: { $0.id == problem.id }),
              let uid = firebase.currentUserId else { return }
        retryList.remove(at: index)
        try? await firebase.removeFromRetryList(uid: uid, problemId: problem.id)
    }
}
