//
//  ProblemDetailView.swift
//  DailyCFSpinStreak
//
//  The solving screen: problem info, open in browser, hidden-tag hint,
//  timer, save to retry list, and finish / verify.
//  Opened from the Spin screen and from the Retry List.
//

import SwiftUI

struct ProblemDetailView: View {
    let problem: Problem
    @ObservedObject var authVM: AuthenticationViewModel
    @ObservedObject var problemVM: ProblemViewModel
    @ObservedObject var timerVM: TimerViewModel
    @ObservedObject var statsVM: StatisticsViewModel

    @State private var showBrowser = false
    @State private var showFinishAlert = false
    @State private var finishedSeconds = 0

    /// .active (on screen), .inactive (e.g. Control Center open) or .background.
    @Environment(\.scenePhase) private var scenePhase

    /// true while statsVM has a verification message to show.
    private var verificationAlertShown: Binding<Bool> {
        Binding(get: { statsVM.verificationMessage != nil },
                set: { if !$0 { statsVM.verificationMessage = nil } })
    }

    /// Status of this problem in the history (nil = never worked on).
    private var savedStatus: SolveStatus? { statsVM.entry(for: problem)?.status }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let savedStatus {
                    statusBanner(savedStatus)
                }

                // Tags are shown only after the hint is used.
                ProblemCard(problem: problem, showTags: timerVM.hintUsed)

                if problem.url != nil {
                    SecondaryButton(title: "Open Problem Statement", systemImage: "safari") {
                        showBrowser = true
                    }
                }

                hintCard

                SolveTimerView(timerVM: timerVM, onFinish: finishSolving)

                SecondaryButton(title: problemVM.isInRetryList(problem) ? "Saved in Retry List" : "Save to Retry List",
                                systemImage: problemVM.isInRetryList(problem) ? "bookmark.fill" : "bookmark",
                                color: Theme.streak) {
                    Task { await problemVM.addToRetryList(problem) }
                }
                .disabled(problemVM.isInRetryList(problem))

                verifyCard
            }
            .padding(Theme.padding)
        }
        .screenBackground()
        .navigationTitle(problem.id)
        .navigationBarTitleDisplayMode(.inline)
        // In-app browser: the app stays active, so the timer keeps running.
        .sheet(isPresented: $showBrowser) {
            if let url = problem.url {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        // onAppear / onDisappear: lifecycle of THIS screen.
        .onAppear {
            timerVM.prepare(for: problem)   // different problem → fresh timer
        }
        .onDisappear {
            // Leaving the screen (Back button or another tab) pauses the timer.
            timerVM.pauseAutomatically(reason: "Paused because you left the problem screen.")
            saveProgress()
        }
        // App lifecycle: pause when the whole app goes to the background.
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                timerVM.pauseAutomatically(reason: "Paused because the app went to the background.")
                saveProgress()
            }
        }
        .alert("Saved as finished", isPresented: $showFinishAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(savedStatus == .verified
                 ? "Time: \(DisplayFormat.duration(finishedSeconds)). This problem is already verified."
                 : "Time: \(DisplayFormat.duration(finishedSeconds)). This is a manual finish, so it does NOT count toward your verified streak. Submit on Codeforces, then tap Verify.")
        }
        .alert("Verification", isPresented: verificationAlertShown) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(statsVM.verificationMessage ?? "")
        }
        .errorAlert($problemVM.errorMessage)
        .errorAlert($statsVM.errorMessage)
    }

    // MARK: - Status banner

    private func statusBanner(_ status: SolveStatus) -> some View {
        let color: Color = status == .verified ? Theme.primary : (status == .finished ? Theme.info : Theme.textSecondary)
        let icon = status == .verified ? "checkmark.seal.fill" : (status == .finished ? "flag.checkered" : "hourglass")
        return Label("Status: \(status.title)", systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Hint

    private var hintCard: some View {
        HStack(spacing: 12) {
            Image(systemName: timerVM.hintUsed ? "lightbulb.fill" : "lightbulb")
                .font(.title2)
                .foregroundStyle(Theme.streak)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(timerVM.hintUsed ? "Hint used" : "Need a hint?")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(timerVM.hintUsed
                     ? "Tags are shown above. This solve will be marked as hint-assisted."
                     : "Reveal the problem's topic tags. It will be recorded in your history.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            if !timerVM.hintUsed {
                Button("Show Hint") { timerVM.useHint() }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.streak)
                    .frame(minHeight: 44)
            }
        }
        .cardStyle()
    }

    // MARK: - Verify (Codeforces API)

    private var verifyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Verified Streak", systemImage: "checkmark.shield")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            if savedStatus == .verified {
                Text("Verified with an Accepted submission on Codeforces. It counts toward your streak.")
                    .font(.footnote)
                    .foregroundStyle(Theme.primary)
            } else if let handle = authVM.currentUser?.cfHandle {
                Text("Submit your solution on Codeforces as \(handle), then tap Verify. Only an Accepted verdict counts toward your streak.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                PrimaryButton(title: "Verify Accepted Submission", systemImage: "checkmark.seal.fill",
                              isLoading: statsVM.isVerifying) {
                    verifySolve()
                }
            } else {
                Text("Connect your Codeforces handle in the Profile tab to verify solves and build your streak.")
                    .font(.footnote)
                    .foregroundStyle(Theme.streak)
            }
        }
        .cardStyle()
    }

    // MARK: - Actions

    /// Saves an "attempted" entry if the timer was used but not finished.
    private func saveProgress() {
        guard timerVM.hasStarted, timerVM.activeProblemId == problem.id else { return }
        let seconds = timerVM.elapsedSeconds
        let hintUsed = timerVM.hintUsed
        Task {
            await statsVM.recordAttempt(problem: problem, durationSeconds: seconds, hintUsed: hintUsed)
        }
    }

    private func verifySolve() {
        guard let user = authVM.currentUser else { return }
        // Read the timer without stopping it: if verification fails the user keeps solving.
        let seconds = timerVM.activeProblemId == problem.id ? timerVM.elapsedSeconds : 0
        let hintUsed = timerVM.hintUsed
        Task {
            if let updatedUser = await statsVM.verifySolve(problem: problem, user: user,
                                                           durationSeconds: seconds, hintUsed: hintUsed) {
                authVM.currentUser = updatedUser          // Dashboard shows the new streak
                _ = timerVM.finish()                       // solved → stop the clock
                await problemVM.removeSolvedProblem(problem)   // no longer needs a retry
            }
        }
    }

    private func finishSolving() {
        let hintUsed = timerVM.hintUsed
        finishedSeconds = timerVM.finish()
        Task {
            await statsVM.recordFinished(problem: problem, durationSeconds: finishedSeconds, hintUsed: hintUsed)
            showFinishAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        ProblemDetailView(problem: SampleData.problems[4], authVM: AuthenticationViewModel(),
                          problemVM: ProblemViewModel(),
                          timerVM: TimerViewModel(), statsVM: StatisticsViewModel())
    }
    .preferredColorScheme(.dark)
}
