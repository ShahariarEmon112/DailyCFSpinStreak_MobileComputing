//
//  ContentView.swift
//  DailyCFSpinStreak
//
//  Root view: a splash while the saved login is checked, then
//  the Login flow (logged out) or the main tab bar (logged in).
//

import SwiftUI

struct ContentView: View {
    // @StateObject: ContentView CREATES and OWNS this view model.
    // It survives view redraws and is passed down to child screens.
    @StateObject private var authVM = AuthenticationViewModel()

    var body: some View {
        Group {
            if authVM.isCheckingSession {
                LoadingView(message: "Signing you in...")
                    .screenBackground()
            } else if authVM.isLoggedIn {
                MainTabView(authVM: authVM)
            } else {
                NavigationStack {
                    LoginView(authVM: authVM)
                }
            }
        }
        .preferredColorScheme(.dark)   // the whole app uses the dark theme
        .tint(Theme.primary)
        // .task runs async work when the view first appears.
        .task {
            await authVM.restoreSession()
        }
    }
}

// No #Preview here: ContentView needs Firebase configured (it runs only in the
// simulator / device). Every other screen has its own preview.
