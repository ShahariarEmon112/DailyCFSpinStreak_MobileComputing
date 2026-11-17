//
//  DashboardView.swift
//  DailyCFSpinStreak
//
//  Home screen: streak, key numbers, today's progress and shortcuts.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    @ObservedObject var statsVM: StatisticsViewModel
    /// @Binding: a two-way connection to MainTabView's `selectedTab` @State.
    @Binding var selectedTab: AppTab

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var user: AppUser? { authVM.currentUser }

    /// Today counts only if a VERIFIED solve happened today (local date).
    private var solvedToday: Bool {
        user?.verifiedDays.contains(StreakService.dayKey(for: Date())) ?? false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Hi, \(user?.name ?? "Coder")")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)

                streakCard

                LazyVGrid(columns: columns, spacing: 12) {
                    StatCard(title: "Verified Solves",
                             value: "\(statsVM.stats.verifiedSolved)",
                             systemImage: "checkmark.seal.fill",
                             color: Theme.primary)
                    StatCard(title: "Attempted Today",
                             value: "\(statsVM.attemptedTodayCount)",
                             systemImage: "calendar",
                             color: Theme.info)
                    StatCard(title: "Avg. Solve Time",
                             value: DisplayFormat.duration(statsVM.stats.averageSeconds),
                             systemImage: "timer",
                             color: Theme.info)
                    StatCard(title: "Highest Rating",
                             value: statsVM.stats.highestRating.map(String.init) ?? "—",
                             systemImage: "chart.line.uptrend.xyaxis",
                             color: Theme.ratingColor(statsVM.stats.highestRating))
                }

                Text("Quick Actions")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 4)

                LazyVGrid(columns: columns, spacing: 12) {
                    QuickActionButton(title: "Spin", systemImage: "dice.fill", color: Theme.primary) {
                        selectedTab = .spin
                    }
                    QuickActionButton(title: "History", systemImage: "clock.arrow.circlepath", color: Theme.info) {
                        selectedTab = .history
                    }
                    QuickActionButton(title: "Retry List", systemImage: "bookmark.fill", color: Theme.streak) {
                        selectedTab = .retry
                    }
                    QuickActionButton(title: "Profile", systemImage: "person.crop.circle", color: Theme.textSecondary) {
                        selectedTab = .profile
                    }
                }
            }
            .padding(Theme.padding)
        }
        .screenBackground()
        .navigationTitle("Dashboard")
        // Recalculate the streak every time the dashboard appears
        // (e.g. it becomes 0 if the user missed yesterday).
        .task {
            await authVM.refreshStreak()
        }
    }

    // MARK: - Streak card (the most important thing on screen)

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.streak)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(user?.currentStreak ?? 0)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("day verified streak")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Best")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text("\(user?.longestStreak ?? 0)")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.streak)
                }
            }

            // Today's progress
            Label(solvedToday
                    ? "Today's verified solve is done. Streak safe!"
                    : "No verified solve today yet. Spin and solve one!",
                  systemImage: solvedToday ? "checkmark.circle.fill" : "exclamationmark.circle")
                .font(.footnote.weight(.medium))
                .foregroundStyle(solvedToday ? Theme.primary : Theme.textSecondary)
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.streak.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

/// Square-ish shortcut button used in the Quick Actions grid.
private struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let authVM = AuthenticationViewModel()
    authVM.currentUser = SampleData.user
    let statsVM = StatisticsViewModel()
    statsVM.history = SampleData.history
    return NavigationStack {
        DashboardView(authVM: authVM, statsVM: statsVM, selectedTab: .constant(.dashboard))
    }
    .preferredColorScheme(.dark)
}
