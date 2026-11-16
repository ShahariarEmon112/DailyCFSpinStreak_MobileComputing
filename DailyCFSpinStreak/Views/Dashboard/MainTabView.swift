//
//  MainTabView.swift
//  DailyCFSpinStreak
//
//  The 5 main tabs. Each tab has its own NavigationStack.
//
//  The shared view models are created HERE with @StateObject, so they live
//  as long as the user is logged in. That is why the solve timer keeps its
//  value when the user switches tabs or goes back.
//

import SwiftUI

/// Identifies each tab, so the Dashboard can switch tabs programmatically.
enum AppTab: Hashable {
    case dashboard, spin, history, retry, profile
}

struct MainTabView: View {
    @ObservedObject var authVM: AuthenticationViewModel

    @StateObject private var problemVM = ProblemViewModel()
    @StateObject private var timerVM = TimerViewModel()
    @StateObject private var statsVM = StatisticsViewModel()

    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "flame.fill", value: AppTab.dashboard) {
                NavigationStack {
                    // $selectedTab passes a @Binding: the Dashboard can change the tab.
                    DashboardView(authVM: authVM, statsVM: statsVM, selectedTab: $selectedTab)
                }
            }

            Tab("Spin", systemImage: "dice.fill", value: AppTab.spin) {
                NavigationStack {
                    SpinView(problemVM: problemVM, timerVM: timerVM, statsVM: statsVM,
                             cfHandle: authVM.currentUser?.cfHandle)
                }
            }

            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                NavigationStack {
                    HistoryView(authVM: authVM, statsVM: statsVM)
                }
            }

            Tab("Retry", systemImage: "bookmark.fill", value: AppTab.retry) {
                NavigationStack {
                    RetryListView(problemVM: problemVM, timerVM: timerVM, statsVM: statsVM)
                }
            }

            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                NavigationStack {
                    ProfileView(authVM: authVM)
                }
            }
        }
        // Load the user's saved data from Firestore once, when the tabs appear.
        .task {
            await statsVM.loadHistory()
            await problemVM.loadRetryList()
        }
    }
}

// No #Preview: MainTabView loads data from Firebase in `.task`,
// which only works in the simulator / on a device.
