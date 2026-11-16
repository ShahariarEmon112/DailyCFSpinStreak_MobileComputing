//
//  StatisticsViewModel.swift
//  DailyCFSpinStreak
//
//  Solve history (stored in Firestore) and the statistics calculated from it.
//

import Foundation
import Combine

final class StatisticsViewModel: ObservableObject {
    @Published var history: [SolveHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firebase = FirebaseService.shared

    // MARK: - Computed values (recalculated whenever `history` changes)

    var stats: UserStats { UserStats.from(history: history) }

    /// Ids of every problem in the history (Spin avoids recommending these again).
    var seenProblemIds: Set<String> {
        Set(history.map { $0.id })
    }

    /// True if there is a verified solve whose accepted submission is from today.
    var solvedToday: Bool {
        history.contains { entry in
            guard entry.status == .verified, let date = entry.verifiedAt else { return false }
            return Calendar.current.isDateInToday(date)
        }
    }

    /// Problems worked on today (any status) — shown as "today's progress".
    var attemptedTodayCount: Int {
        history.filter { Calendar.current.isDateInToday($0.attemptedAt) }.count
    }

    /// The saved entry for a problem, if the user worked on it before.
    func entry(for problem: Problem) -> SolveHistory? {
        history.first { $0.id == problem.id }
    }

    // MARK: - Firestore READ

    func loadHistory() async {
        guard let uid = firebase.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            history = try await firebase.fetchHistory(uid: uid)
        } catch {
            errorMessage = "Could not load your history: \(error.localizedDescription)"
        }
    }

    // MARK: - Firestore CREATE / UPDATE

    /// Saves progress when the user leaves a problem without finishing it.
    /// Never downgrades a problem that is already finished or verified.
    func recordAttempt(problem: Problem, durationSeconds: Int, hintUsed: Bool) async {
        let existing = entry(for: problem)
        if let existing, existing.status != .attempted { return }

        let newEntry = SolveHistory(problem: problem,
                                    durationSeconds: durationSeconds,
                                    hintUsed: hintUsed || (existing?.hintUsed ?? false),
                                    status: .attempted,
                                    attemptedAt: Date(),
                                    verifiedAt: nil)
        await save(newEntry)
    }

    /// Saves a manual "Finish". This NEVER changes the verified streak.
    /// If the problem was already verified it stays verified.
    func recordFinished(problem: Problem, durationSeconds: Int, hintUsed: Bool) async {
        let existing = entry(for: problem)
        let newEntry = SolveHistory(problem: problem,
                                    durationSeconds: durationSeconds,
                                    hintUsed: hintUsed || (existing?.hintUsed ?? false),
                                    status: existing?.status == .verified ? .verified : .finished,
                                    attemptedAt: Date(),
                                    verifiedAt: existing?.verifiedAt)
        await save(newEntry)
    }

    /// Writes one entry to Firestore, then updates the local list (newest first).
    private func save(_ entry: SolveHistory) async {
        guard let uid = firebase.currentUserId else { return }
        do {
            try await firebase.saveHistory(uid: uid, entry: entry)
            history.removeAll { $0.id == entry.id }   // no duplicates
            history.insert(entry, at: 0)
        } catch {
            errorMessage = "Could not save your progress: \(error.localizedDescription)"
        }
    }
}
