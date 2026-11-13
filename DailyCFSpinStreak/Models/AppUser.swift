//
//  AppUser.swift
//  DailyCFSpinStreak
//
//  The logged-in user's profile. Stored in Firestore at users/{uid}.
//  (Named AppUser so it does not clash with Firebase's own `User` type.)
//

import Foundation

nonisolated struct AppUser: Codable, Identifiable {
    var id: String                 // Firebase Auth uid
    var name: String
    var email: String
    var cfHandle: String?          // Codeforces handle, nil until connected
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    /// Days with at least one API-verified accepted solve, as "yyyy-MM-dd"
    /// strings in the user's local time zone. A day can appear only once,
    /// so solving 3 problems on one day still counts as one streak day.
    var verifiedDays: [String] = []
    var createdAt: Date = Date()
}
