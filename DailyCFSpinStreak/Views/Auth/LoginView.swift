//
//  LoginView.swift
//  DailyCFSpinStreak
//
//  Email + password login. Links to RegisterView.
//

import SwiftUI

struct LoginView: View {
    // @ObservedObject: the view model is owned by ContentView, we only watch it.
    @ObservedObject var authVM: AuthenticationViewModel

    // @State: simple values that belong only to this screen.
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                AppHeader(subtitle: "Spin a problem. Solve it. Keep the streak.")

                VStack(spacing: 16) {
                    FormField(title: "Email", systemImage: "envelope") {
                        TextField("you@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    FormField(title: "Password", systemImage: "lock") {
                        SecureField("At least 6 characters", text: $password)
                            .textContentType(.password)
                    }
                }

                PrimaryButton(title: "Log In", systemImage: "arrow.right.circle.fill",
                              isLoading: authVM.isLoading) {
                    // Button actions are not async, so we start a Task to call async code.
                    Task { await authVM.login(email: email, password: password) }
                }

                NavigationLink {
                    RegisterView(authVM: authVM)
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(Theme.textSecondary)
                        Text("Register")
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.primary)
                    }
                    .font(.subheadline)
                    .frame(minHeight: 44)
                }
            }
            .padding(24)
        }
        .screenBackground()
        .errorAlert($authVM.errorMessage)
    }
}

/// Logo + app name shown at the top of Login and Register.
struct AppHeader: View {
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.streak)
                .padding(.top, 32)
                .accessibilityHidden(true)
            Text("CF Spin Streak")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    NavigationStack {
        LoginView(authVM: AuthenticationViewModel())
    }
    .preferredColorScheme(.dark)
}
