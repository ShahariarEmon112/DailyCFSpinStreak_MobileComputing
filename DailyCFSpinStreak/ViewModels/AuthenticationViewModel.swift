//
//  AuthenticationViewModel.swift
//  DailyCFSpinStreak
//
//  Handles register / login / logout and holds the current user.
//
//  STEP 2: works fully offline (no Firebase yet) so the screens can be tested.
//  STEP 3: the bodies of login/register/logout will call FirebaseService.
//

import Foundation
import Combine

final class AuthenticationViewModel: ObservableObject {
    // @Published: every view observing this object redraws when these change.
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isLoggedIn: Bool { currentUser != nil }

    // MARK: - Validation (shared by Login and Register)

    /// Returns an error message, or nil if the input is valid.
    func validate(email: String, password: String) -> String? {
        if email.trimmingCharacters(in: .whitespaces).isEmpty || !email.contains("@") {
            return "Please enter a valid email address."
        }
        if password.count < 6 {
            return "Password must be at least 6 characters."
        }
        return nil
    }

    // MARK: - Actions

    func login(email: String, password: String) {
        if let error = validate(email: email, password: password) {
            errorMessage = error
            return
        }
        // Placeholder (Step 3 replaces this with Firebase Auth).
        currentUser = AppUser(id: UUID().uuidString, name: "Coder", email: email)
    }

    func register(name: String, email: String, password: String, confirmPassword: String) {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your name."
            return
        }
        if let error = validate(email: email, password: password) {
            errorMessage = error
            return
        }
        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            return
        }
        // Placeholder (Step 3 replaces this with Firebase Auth + Firestore).
        currentUser = AppUser(id: UUID().uuidString, name: name, email: email)
    }

    func logout() {
        currentUser = nil
    }

    /// Saves the Codeforces handle on the profile.
    /// Step 6 will first check with the Codeforces API that the handle exists.
    func connectHandle(_ handle: String) {
        let trimmed = handle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter your Codeforces handle."
            return
        }
        currentUser?.cfHandle = trimmed
    }
}
