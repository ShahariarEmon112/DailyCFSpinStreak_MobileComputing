//
//  RegisterView.swift
//  DailyCFSpinStreak
//
//  Create a new account with name, email and password.
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var authVM: AuthenticationViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                AppHeader(subtitle: "Create your account to start a streak.")

                VStack(spacing: 16) {
                    FormField(title: "Name", systemImage: "person") {
                        TextField("Your name", text: $name)
                            .textContentType(.name)
                    }
                    FormField(title: "Email", systemImage: "envelope") {
                        TextField("you@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    FormField(title: "Password", systemImage: "lock") {
                        SecureField("At least 6 characters", text: $password)
                            .textContentType(.newPassword)
                    }
                    FormField(title: "Confirm Password", systemImage: "lock.rotation") {
                        SecureField("Type the password again", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                }

                PrimaryButton(title: "Create Account", systemImage: "person.badge.plus",
                              isLoading: authVM.isLoading) {
                    authVM.register(name: name, email: email,
                                    password: password, confirmPassword: confirmPassword)
                }
            }
            .padding(24)
        }
        .screenBackground()
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert($authVM.errorMessage)
    }
}

#Preview {
    NavigationStack {
        RegisterView(authVM: AuthenticationViewModel())
    }
    .preferredColorScheme(.dark)
}
