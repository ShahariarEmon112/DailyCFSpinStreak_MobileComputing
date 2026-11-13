//
//  HistoryView.swift
//  DailyCFSpinStreak
//
//  Statistics at the top, then every attempted / finished / verified problem.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @ObservedObject var statsVM: StatisticsViewModel

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        List {
            Section {
                statsGrid
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } header: {
                sectionHeader("Statistics")
            }

            Section {
                if statsVM.isLoading {
                    LoadingView(message: "Loading history...")
                        .frame(height: 120)
                        .listRowBackground(Color.clear)
                } else if statsVM.history.isEmpty {
                    EmptyStateView(systemImage: "clock.arrow.circlepath",
                                   title: "No attempts yet",
                                   message: "Problems you finish or verify will show up here.")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(statsVM.history) { entry in
                        HistoryRowView(entry: entry)
                            .listRowBackground(Theme.card)
                    }
                }
            } header: {
                sectionHeader("Problems")
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("History")
    }

    private var statsGrid: some View {
        let stats = statsVM.stats
        return LazyVGrid(columns: columns, spacing: 12) {
            StatCard(title: "Verified Solves", value: "\(stats.verifiedSolved)",
                     systemImage: "checkmark.seal.fill", color: Theme.primary)
            StatCard(title: "Manual Finishes", value: "\(stats.manuallyFinished)",
                     systemImage: "flag.checkered", color: Theme.info)
            StatCard(title: "Avg. Solve Time", value: DisplayFormat.duration(stats.averageSeconds),
                     systemImage: "timer", color: Theme.info)
            StatCard(title: "Highest Rating", value: stats.highestRating.map(String.init) ?? "—",
                     systemImage: "chart.line.uptrend.xyaxis",
                     color: Theme.ratingColor(stats.highestRating))
            StatCard(title: "Current Streak", value: "\(authVM.currentUser?.currentStreak ?? 0)",
                     systemImage: "flame.fill", color: Theme.streak)
            StatCard(title: "Best Streak", value: "\(authVM.currentUser?.longestStreak ?? 0)",
                     systemImage: "trophy.fill", color: Theme.streak)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Theme.textPrimary)
            .textCase(nil)
    }
}

#Preview {
    let authVM = AuthenticationViewModel()
    authVM.currentUser = SampleData.user
    let statsVM = StatisticsViewModel()
    statsVM.history = SampleData.history
    return NavigationStack {
        HistoryView(authVM: authVM, statsVM: statsVM)
    }
    .preferredColorScheme(.dark)
}
