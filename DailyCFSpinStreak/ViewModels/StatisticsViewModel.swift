//
//  StatisticsViewModel.swift
//  DailyCFSpinStreak
//
//  Solve history (stored in Firestore), the statistics calculated from it,
//  and verification of Accepted submissions via the Codeforces API.
//

import Foundation
import Combine

final class StatisticsViewModel: ObservableObject {
    @Published var history: [SolveHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isVerifying = false
    /// Success / info text after a verification attempt (shown in an alert).
    @Published var verificationMessage: String?

    private let firebase = FirebaseService.shared
    private let api = CodeforcesAPIService.shared

    // MARK: - Computed values (recalculated whenever `history` changes)

    var stats: UserStats { UserStats.from(history: history) }

    /// Ids of every problem in the history (Spin avoids recommending these again).
    var seenProblemIds: Set<String> {
        Set(history.map { $0.id })
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
    /// Returns true if it was saved.
    @discardableResult
    private func save(_ entry: SolveHistory) async -> Bool {
        guard let uid = firebase.currentUserId else { return false }
        do {
            try await firebase.saveHistory(uid: uid, entry: entry)
            history.removeAll { $0.id == entry.id }   // no duplicates
            history.insert(entry, at: 0)
            return true
        } catch {
            errorMessage = "Could not save your progress: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Verification (Codeforces API) + streak

    /// Checks Codeforces for an ACCEPTED submission of `problem` by the user's handle.
    /// Only then is the problem marked "verified" and the streak updated.
    /// Returns the updated user (new streak values) on success, otherwise nil.
    func verifySolve(problem: Problem, user: AppUser, durationSeconds: Int, hintUsed: Bool) async -> AppUser? {
        guard let handle = user.cfHandle, !handle.isEmpty else {
            errorMessage = "Connect your Codeforces handle in the Profile tab first."
            return nil
        }

        // Duplicate protection: a problem can only be verified (and counted) once.
        let existing = entry(for: problem)
        if existing?.status == .verified {
            verificationMessage = "\(problem.id) is already verified. Each problem counts only once."
            return nil
        }

        isVerifying = true
        defer { isVerifying = false }

        // 1. Download the user's submissions from Codeforces.
        let submissions: [Submission]
        do {
            submissions = try await api.fetchSubmissions(handle: handle)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }

        // 2. Keep only submissions for exactly this problem (same contest id + index).
        let forThisProblem = submissions.filter {
            $0.problem.contestId == problem.contestId && $0.problem.index == problem.index
        }

        // 3. The EARLIEST Accepted submission is the real solving time.
        guard let firstAccepted = forThisProblem
            .filter({ $0.isAccepted })
            .min(by: { $0.creationTimeSeconds < $1.creationTimeSeconds }) else {
            let stillJudging = forThisProblem.contains { $0.verdict == nil || $0.verdict == "TESTING" }
            errorMessage = stillJudging
                ? "Your submission for \(problem.id) is still being judged. Try again in a minute."
                : "No Accepted submission for \(problem.id) found on \(handle). Solve it on Codeforces first, then verify."
            return nil
        }
        let solvedDate = firstAccepted.submittedAt

        // 4. Save the history entry as VERIFIED.
        let verifiedEntry = SolveHistory(problem: problem,
                                         durationSeconds: durationSeconds > 0 ? durationSeconds : (existing?.durationSeconds ?? 0),
                                         hintUsed: hintUsed || (existing?.hintUsed ?? false),
                                         status: .verified,
                                         attemptedAt: Date(),
                                         verifiedAt: solvedDate)
        guard await save(verifiedEntry) else { return nil }

        // 5. Add the LOCAL solving day. verifiedDays works like a set, so two
        //    solves on the same day still add only one streak day.
        var updatedUser = user
        let dayKey = StreakService.dayKey(for: solvedDate)
        if !updatedUser.verifiedDays.contains(dayKey) {
            updatedUser.verifiedDays.append(dayKey)
            updatedUser.verifiedDays.sort()
        }
        updatedUser.currentStreak = StreakService.currentStreak(verifiedDays: updatedUser.verifiedDays)
        updatedUser.longestStreak = max(updatedUser.longestStreak,
                                        StreakService.longestStreak(verifiedDays: updatedUser.verifiedDays))

        // 6. Save the new streak in Firestore.
        do {
            try await firebase.updateStreak(uid: updatedUser.id,
                                            verifiedDays: updatedUser.verifiedDays,
                                            currentStreak: updatedUser.currentStreak,
                                            longestStreak: updatedUser.longestStreak)
        } catch {
            errorMessage = "Verified, but the streak could not be saved: \(error.localizedDescription)"
            return nil
        }

        verificationMessage = "Accepted on \(DisplayFormat.shortDate(solvedDate)). Current streak: \(updatedUser.currentStreak) day(s)."
        return updatedUser
    }
}
