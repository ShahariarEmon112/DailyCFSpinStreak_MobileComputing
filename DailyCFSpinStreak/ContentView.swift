//
//  ContentView.swift
//  DailyCFSpinStreak
//
//  Root view: shows the Login flow when logged out,
//  and the main tab bar when logged in.
//

import SwiftUI

struct ContentView: View {
    // @StateObject: ContentView CREATES and OWNS this view model.
    // It survives view redraws and is passed down to child screens.
    @StateObject private var authVM = AuthenticationViewModel()

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                MainTabView(authVM: authVM)
            } else {
                NavigationStack {
                    LoginView(authVM: authVM)
                }
            }
        }
        .preferredColorScheme(.dark)   // the whole app uses the dark theme
        .tint(Theme.primary)
    }
}

#Preview {
    ContentView()
}
