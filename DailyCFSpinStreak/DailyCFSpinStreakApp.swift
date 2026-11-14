//
//  DailyCFSpinStreakApp.swift
//  DailyCFSpinStreak
//
//  App entry point.
//

import SwiftUI
import UIKit
import FirebaseCore

/// DELEGATE PATTERN: UIKit tells this object about app events
/// (here: "the app finished launching"). SwiftUI apps connect it with
/// @UIApplicationDelegateAdaptor below. This is where Firebase is started,
/// as recommended by the Firebase documentation.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Reads GoogleService-Info.plist and connects the app to your Firebase project.
        FirebaseApp.configure()
        return true
    }
}

@main
struct DailyCFSpinStreakApp: App {
    // Tells SwiftUI to create our AppDelegate and forward app events to it.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
