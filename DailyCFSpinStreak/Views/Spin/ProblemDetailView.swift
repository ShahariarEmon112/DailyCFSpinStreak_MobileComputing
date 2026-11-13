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
    @ObservedObject var problemVM: ProblemViewModel
    @ObservedObject var timerVM: TimerViewModel
    @ObservedObject var statsVM: StatisticsViewModel

    @State private var showFinishAlert = false
    @State private var finishedSeconds = 0

    // Environment value that opens a URL in Safari.
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Tags are shown only after the hint is used.
                ProblemCard(problem: problem, showTags: timerVM.hintUsed)

                if let url = problem.url {
                    SecondaryButton(title: "Open on Codeforces", systemImage: "safari") {
                        openURL(url)
                    }
                }

                hintCard

                SolveTimerView(timerVM: timerVM, onFinish: finishSolving)

                SecondaryButton(title: problemVM.isInRetryList(problem) ? "Saved in Retry List" : "Save to Retry List",
                                systemImage: problemVM.isInRetryList(problem) ? "bookmark.fill" : "bookmark",
                                color: Theme.streak) {
                    problemVM.addToRetryList(problem)
                }
                .disabled(problemVM.isInRetryList(problem))

                verifyCard
            }
            .padding(Theme.padding)
        }
        .screenBackground()
        .navigationTitle(problem.id)
        .navigationBarTitleDisplayMode(.inline)
        // onAppear / onDisappear: lifecycle of THIS screen.
        .onAppear {
            timerVM.prepare(for: problem)   // new problem → fresh timer
        }
        .onDisappear {
            timerVM.pause()                 // leaving the screen pauses the timer
        }
        .alert("Saved as finished", isPresented: $showFinishAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Time: \(DisplayFormat.duration(finishedSeconds)). This is a manual finish, so it does NOT count toward your verified streak. Submit on Codeforces, then tap Verify.")
        }
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

    // MARK: - Verify (implemented in Step 6)

    private var verifyCard: some View {
        VStack(spacing: 8) {
            SecondaryButton(title: "Verify on Codeforces", systemImage: "checkmark.shield",
                            color: Theme.primary) {}
                .disabled(true)
                .opacity(0.5)
            Text("Accepted-submission verification is added in Step 6.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Actions

    private func finishSolving() {
        let hintUsed = timerVM.hintUsed
        finishedSeconds = timerVM.finish()
        statsVM.recordFinished(problem: problem, durationSeconds: finishedSeconds, hintUsed: hintUsed)
        showFinishAlert = true
    }
}

#Preview {
    NavigationStack {
        ProblemDetailView(problem: SampleData.problems[4], problemVM: ProblemViewModel(),
                          timerVM: TimerViewModel(), statsVM: StatisticsViewModel())
    }
    .preferredColorScheme(.dark)
}
