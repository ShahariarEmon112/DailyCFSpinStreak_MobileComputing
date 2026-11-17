//
//  RetryListView.swift
//  DailyCFSpinStreak
//
//  Problems saved for later. Swipe left on a row to delete it,
//  tap a row to reopen the problem.
//

import SwiftUI

struct RetryListView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @ObservedObject var problemVM: ProblemViewModel
    @ObservedObject var timerVM: TimerViewModel
    @ObservedObject var statsVM: StatisticsViewModel

    var body: some View {
        Group {
            if problemVM.retryList.isEmpty {
                EmptyStateView(systemImage: "bookmark",
                               title: "No saved problems",
                               message: "Tap \"Save to Retry List\" on a hard problem to come back to it later.")
            } else {
                List {
                    // ForEach (not just List(items)) is needed for .onDelete.
                    ForEach(problemVM.retryList) { problem in
                        NavigationLink(value: problem) {
                            RetryRow(problem: problem)
                        }
                        .listRowBackground(Theme.card)
                    }
                    .onDelete(perform: problemVM.removeFromRetryList)   // swipe-to-delete
                }
                .scrollContentBackground(.hidden)
                .refreshable {   // pull down to reload from Firestore
                    await problemVM.loadRetryList()
                }
            }
        }
        .screenBackground()
        .navigationTitle("Retry List")
        .toolbar {
            if !problemVM.retryList.isEmpty {
                EditButton()   // alternative to swiping: tap Edit, then the red buttons
            }
        }
        .errorAlert($problemVM.errorMessage)
        .navigationDestination(for: Problem.self) { problem in
            ProblemDetailView(problem: problem, authVM: authVM, problemVM: problemVM,
                              timerVM: timerVM, statsVM: statsVM)
        }
    }
}

/// One row: name, id and rating. Tags stay hidden (they are the hint).
private struct RetryRow: View {
    let problem: Problem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(problem.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(problem.id)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            RatingBadge(rating: problem.rating)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    let problemVM = ProblemViewModel()
    problemVM.retryList = Array(SampleData.problems.prefix(3))
    return NavigationStack {
        RetryListView(authVM: AuthenticationViewModel(), problemVM: problemVM,
                      timerVM: TimerViewModel(), statsVM: StatisticsViewModel())
    }
    .preferredColorScheme(.dark)
}
