//
//  AuthenticationViewModel.swift
//  DailyCFSpinStreak
//
//  Handles register / login / logout and holds the current user's profile.
//  Uses FirebaseService for Firebase Auth + Firestore.
//

import Foundation
import Combine
import FirebaseAuth   // only for AuthErrorCode (friendly error messages)

final class AuthenticationViewModel: ObservableObject {
    // @Published: every view observing this object redraws when these change.
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    /// True while we check for a saved login at app start (shows a splash).
    @Published var isCheckingSession = true
    @Published var errorMessage: String?

    var isLoggedIn: Bool { currentUser != nil }

    private let firebase = FirebaseService.shared

    // MARK: - Session persistence

    /// Called once by ContentView when the app starts.
    /// Firebase remembers the login on the device. If a user is still signed in,
    /// load their profile from Firestore so they skip the Login screen.
    func restoreSession() async {
        if let uid = firebase.currentUserId {
            await loadProfile(uid: uid, email: firebase.currentUserEmail ?? "")
        }
        isCheckingSession = false
    }

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

    // MARK: - Actions (async: they wait for Firebase over the network)

    func login(email: String, password: String) async {
        let email = email.trimmingCharacters(in: .whitespaces)
        if let error = validate(email: email, password: password) {
            errorMessage = error
            return
        }

        isLoading = true
        defer { isLoading = false }   // runs when the function ends, success or error

        do {
            let uid = try await firebase.login(email: email, password: password)
            await loadProfile(uid: uid, email: email)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func register(name: String, email: String, password: String, confirmPassword: String) async {
        let name = name.trimmingCharacters(in: .whitespaces)
        let email = email.trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
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

        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Create the Auth account.
            let uid = try await firebase.register(email: email, password: password)
            // 2. Create the Firestore profile document users/{uid}.
            let newUser = AppUser(id: uid, name: name, email: email)
            try await firebase.saveUserProfile(newUser)
            // 3. Logged in → ContentView switches to the main tabs.
            currentUser = newUser
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    func logout() {
        do {
            try firebase.logout()
            currentUser = nil
        } catch {
            errorMessage = "Could not log out: \(error.localizedDescription)"
        }
    }

    /// Saves the Codeforces handle to Firestore.
    /// Step 6 will first check with the Codeforces API that the handle exists.
    func connectHandle(_ handle: String) async {
        let trimmed = handle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter your Codeforces handle."
            return
        }
        guard let uid = currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await firebase.updateHandle(uid: uid, handle: trimmed)
            currentUser?.cfHandle = trimmed
        } catch {
            errorMessage = "Could not save handle: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    /// Reads users/{uid}. If the document is missing (e.g. account made in the
    /// Firebase console), creates a basic profile so the app still works.
    private func loadProfile(uid: String, email: String) async {
        do {
            if let profile = try await firebase.fetchUserProfile(uid: uid) {
                currentUser = profile
            } else {
                let fallbackName = email.split(separator: "@").first.map(String.init) ?? "Coder"
                let newUser = AppUser(id: uid, name: fallbackName, email: email)
                try await firebase.saveUserProfile(newUser)
                currentUser = newUser
            }
        } catch {
            errorMessage = "Could not load your profile: \(error.localizedDescription)"
        }
    }

    /// Turns Firebase Auth error codes into messages a user understands.
    private func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        switch code {
        case .wrongPassword, .invalidCredential, .userNotFound:
            return "Incorrect email or password."
        case .emailAlreadyInUse:
            return "An account with this email already exists. Try logging in."
        case .invalidEmail:
            return "That email address is not valid."
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .networkError:
            return "No internet connection. Please check your network and try again."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        default:
            return error.localizedDescription
        }
    }
}
