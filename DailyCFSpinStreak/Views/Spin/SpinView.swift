//
//  SpinView.swift
//  DailyCFSpinStreak
//
//  Choose a rating range and topics, then Spin for a random problem.
//

import SwiftUI

struct SpinView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @ObservedObject var problemVM: ProblemViewModel
    @ObservedObject var timerVM: TimerViewModel
    @ObservedObject var statsVM: StatisticsViewModel
    /// Connected Codeforces handle (nil if not connected yet).
    private var cfHandle: String? { authVM.currentUser?.cfHandle }

    private let tagColumns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ratingCard
                tagCard

                PrimaryButton(title: "Spin", systemImage: "dice.fill",
                              color: Theme.streak, isLoading: problemVM.isLoading) {
                    Task { await problemVM.spin(seenProblemIds: statsVM.seenProblemIds) }
                }

                if problemVM.loadedProblemCount > 0 {
                    Text("\(problemVM.loadedProblemCount) problems loaded from Codeforces")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }

                resultSection
            }
            .padding(Theme.padding)
        }
        .screenBackground()
        .navigationTitle("Spin")
        // Value-based navigation: NavigationLink(value: problem) below opens this.
        .navigationDestination(for: Problem.self) { problem in
            ProblemDetailView(problem: problem, authVM: authVM, problemVM: problemVM,
                              timerVM: timerVM, statsVM: statsVM)
        }
        .errorAlert($problemVM.errorMessage)
        // Runs when the screen appears AND again whenever the handle changes.
        .task(id: cfHandle) {
            await problemVM.loadSolvedProblems(handle: cfHandle)
        }
    }

    // MARK: - Rating range

    private var ratingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Rating Range", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            Stepper(value: $problemVM.minRating,
                    in: ProblemViewModel.lowestRating...ProblemViewModel.highestRating,
                    step: 100) {
                ratingRow(title: "Minimum", rating: problemVM.minRating)
            }
            Stepper(value: $problemVM.maxRating,
                    in: ProblemViewModel.lowestRating...ProblemViewModel.highestRating,
                    step: 100) {
                ratingRow(title: "Maximum", rating: problemVM.maxRating)
            }
        }
        .cardStyle()
        // Keep min <= max whenever one of them changes.
        .onChange(of: problemVM.minRating) { problemVM.fixRatingRange(changedMin: true) }
        .onChange(of: problemVM.maxRating) { problemVM.fixRatingRange(changedMin: false) }
    }

    private func ratingRow(title: String, rating: Int) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text("\(rating)")
                .font(.system(.body, design: .monospaced).weight(.bold))
                .foregroundStyle(Theme.ratingColor(rating))
        }
    }

    // MARK: - Topic tags

    private var tagCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Topics", systemImage: "tag")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if !problemVM.selectedTags.isEmpty {
                    Button("Clear") { problemVM.selectedTags.removeAll() }
                        .font(.subheadline)
                }
            }
            Text(problemVM.selectedTags.isEmpty
                 ? "Any topic. Tap to require specific topics."
                 : "Problem must have all selected topics.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)

            LazyVGrid(columns: tagColumns, alignment: .leading, spacing: 8) {
                ForEach(ProblemViewModel.availableTags, id: \.self) { tag in
                    let isSelected = problemVM.selectedTags.contains(tag)
                    Button {
                        problemVM.toggleTag(tag)
                    } label: {
                        TagChip(text: tag, color: Theme.primary, isSelected: isSelected)
                            .frame(minHeight: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Spin result

    @ViewBuilder
    private var resultSection: some View {
        if problemVM.isLoading {
            LoadingView(message: problemVM.loadedProblemCount == 0
                        ? "Downloading problems from Codeforces..."
                        : "Finding a problem...")
                .frame(height: 160)
        } else if let problem = problemVM.currentProblem {
            VStack(spacing: 12) {
                // Tags stay hidden here; they can be revealed as a hint while solving.
                ProblemCard(problem: problem, showTags: false)

                if let info = problemVM.infoMessage {
                    Label(info, systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }

                NavigationLink(value: problem) {
                    PrimaryLabel(title: "Start Solving", systemImage: "play.fill")
                }
                .buttonStyle(.plain)
            }
        } else {
            EmptyStateView(systemImage: "dice",
                           title: "Ready to spin?",
                           message: "Pick a rating range and topics, then tap Spin to get a random problem.")
                .frame(height: 200)
        }
    }
}

#Preview {
    NavigationStack {
        SpinView(authVM: AuthenticationViewModel(), problemVM: ProblemViewModel(),
                 timerVM: TimerViewModel(), statsVM: StatisticsViewModel())
    }
    .preferredColorScheme(.dark)
}
