# Daily Codeforces Spin Streak

An iOS app (SwiftUI + Firebase + Codeforces API) that helps competitive programmers keep a daily habit:
spin a random Codeforces problem, solve it against a timer, and keep a **verified** daily streak.

Built as a Mobile Computing lab mini-project.

## Progress

- [x] Step 1: Project inspection and plan
- [x] Step 2: SwiftUI UI and navigation (placeholder data)
- [ ] Step 3: Firebase Authentication and Firestore
- [ ] Step 4: Codeforces API and JSON parsing
- [ ] Step 5: Spin, timer, hints, retry list, history with real data
- [ ] Step 6: Accepted-submission verification and daily streak
- [ ] Step 7: Testing, polish and documentation

## Requirements

- Xcode with the iOS 18+ SDK (deployment target: **iOS 18.0**)
- A Firebase project with **Email/Password** sign-in and **Cloud Firestore** enabled

## Setup

1. Clone the repo and open `DailyCFSpinStreak.xcodeproj`.
2. **Add your own `GoogleService-Info.plist`.** It is git-ignored on purpose, so it is not in this repo.
   Download it from Firebase Console → Project settings → Your apps → iOS app, and drag it into the
   `DailyCFSpinStreak/` folder in Xcode.
3. Xcode resolves the Firebase Swift package automatically (FirebaseAuth, FirebaseCore, FirebaseFirestore).
4. Choose an iPhone simulator and press **Run** (⌘R).

## Folder structure (MVVM)

```
DailyCFSpinStreak/
├── DailyCFSpinStreakApp.swift   app entry point
├── ContentView.swift            root: Login flow or MainTabView
├── Models/                      Problem, AppUser, SolveHistory, UserStats, SampleData
├── ViewModels/                  Authentication, Problem, Timer, Statistics
├── Services/                    (Step 3+) Firebase, Codeforces API, Streak
├── Views/                       Auth, Dashboard, Spin, History, Retry, Profile
└── Components/                  Theme + reusable views (cards, buttons, chips...)
```
