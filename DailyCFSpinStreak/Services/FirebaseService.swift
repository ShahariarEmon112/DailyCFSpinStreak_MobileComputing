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

    /// UPDATE: saves the streak fields after a verified solve.
    func updateStreak(uid: String, verifiedDays: [String], currentStreak: Int, longestStreak: Int) async throws {
        try await userDocument(uid).updateData([
            "verifiedDays": verifiedDays,
            "currentStreak": currentStreak,
            "longestStreak": longestStreak,
        ])
    }

    // MARK: - Solve history (users/{uid}/history/{problemId})

    private func historyCollection(_ uid: String) -> CollectionReference {
        userDocument(uid).collection("history")
    }

    /// CREATE or UPDATE: the document id is the problem id ("4A"), so saving the
    /// same problem again overwrites the old entry instead of making a duplicate.
    func saveHistory(uid: String, entry: SolveHistory) async throws {
        let data = try Firestore.Encoder().encode(entry)
        try await historyCollection(uid).document(entry.id).setData(data)
    }

    /// READ: all history entries, newest first.
    func fetchHistory(uid: String) async throws -> [SolveHistory] {
        let snapshot = try await historyCollection(uid)
            .order(by: "attemptedAt", descending: true)
            .getDocuments()
        // compactMap + try? skips any document that cannot be decoded.
        return snapshot.documents.compactMap { try? $0.data(as: SolveHistory.self) }
    }

    // MARK: - Retry list (users/{uid}/retry/{problemId})

    private func retryCollection(_ uid: String) -> CollectionReference {
        userDocument(uid).collection("retry")
    }

    /// CREATE: saves the problem plus an "addedAt" date used for sorting.
    func addToRetryList(uid: String, problem: Problem) async throws {
        var data = try Firestore.Encoder().encode(problem)
        data["addedAt"] = Timestamp(date: Date())
        try await retryCollection(uid).document(problem.id).setData(data)
    }

    /// READ: saved problems, most recently added first.
    /// ("addedAt" is not part of Problem, so Codable simply ignores it.)
    func fetchRetryList(uid: String) async throws -> [Problem] {
        let snapshot = try await retryCollection(uid)
            .order(by: "addedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Problem.self) }
    }

    /// DELETE: removes one saved problem.
    func removeFromRetryList(uid: String, problemId: String) async throws {
        try await retryCollection(uid).document(problemId).delete()
    }
}
