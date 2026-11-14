//
//  FirebaseService.swift
//  DailyCFSpinStreak
//
//  The ONLY file that talks to Firebase. ViewModels call these functions,
//  so views never import Firebase directly.
//
//  Firestore layout:
//    users/{uid}                       → AppUser (profile + streak)
//    users/{uid}/history/{problemId}   → SolveHistory   (Step 5)
//    users/{uid}/retry/{problemId}     → Problem        (Step 5)
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseService {
    /// One shared instance used by the whole app (singleton).
    static let shared = FirebaseService()
    private init() {}

    // Computed, so Firestore is only touched after FirebaseApp.configure() ran.
    private var db: Firestore { Firestore.firestore() }

    // MARK: - Authentication

    /// uid of the logged-in user, or nil. Firebase keeps the login saved on the
    /// device, so after restarting the app this is still set (session persistence).
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    var currentUserEmail: String? {
        Auth.auth().currentUser?.email
    }

    /// Creates a Firebase Auth account and returns the new user's uid.
    func register(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    /// Logs in and returns the user's uid.
    func login(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func logout() throws {
        try Auth.auth().signOut()
    }

    // MARK: - User profile (Firestore CRUD on users/{uid})

    private func userDocument(_ uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    /// CREATE: saves a full profile document.
    func saveUserProfile(_ user: AppUser) async throws {
        // Encoder turns the Codable struct into a [String: Any] dictionary.
        let data = try Firestore.Encoder().encode(user)
        try await userDocument(user.id).setData(data)
    }

    /// READ: returns the profile, or nil if the document does not exist yet.
    func fetchUserProfile(uid: String) async throws -> AppUser? {
        let snapshot = try await userDocument(uid).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: AppUser.self)
    }

    /// UPDATE: changes only the Codeforces handle field.
    func updateHandle(uid: String, handle: String) async throws {
        try await userDocument(uid).updateData(["cfHandle": handle])
    }
}
