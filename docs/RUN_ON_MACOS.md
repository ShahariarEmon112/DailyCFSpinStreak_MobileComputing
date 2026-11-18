# How to Run Daily CF Spin Streak on macOS

A step-by-step guide to running the app on a Mac, from a fresh machine to the app running in the
iPhone Simulator. It takes about 30–60 minutes the first time, mostly downloading Xcode.

---

## What you need

| Item | Notes |
|---|---|
| A Mac | Apple Silicon or Intel, with a recent macOS that your Xcode version supports |
| Xcode | From the Mac App Store, free. Needs the **iOS 18 SDK or newer**. See [the project-format note](#important-project-format-note) |
| Internet | To download Firebase packages and Codeforces problems |
| Your `GoogleService-Info.plist` | From the Firebase console. It is **not** in GitHub on purpose |
| An Apple ID | Only needed to run on a real iPhone. The Simulator needs no account |

---

## Step 1: Install Xcode

1. Open the **App Store** → search **Xcode** → **Get / Install** (large download).
2. Open Xcode once and accept the license. When it asks which platforms to install, tick **iOS**
   (this downloads the iPhone Simulator).
3. Optionally, check the installation in **Terminal**:
   ```bash
   xcodebuild -version
   ```

## Step 2: Get the code

In **Terminal**:

```bash
cd ~/Desktop
git clone https://github.com/ShahariarEmon112/DailyCFSpinStreak_MobileComputing.git
cd DailyCFSpinStreak_MobileComputing
```

If Git asks to install the "command line developer tools", click **Install**, then run the command
again. Alternatively, download the ZIP from GitHub (**Code → Download ZIP**) and unzip it.

## Step 3: Add the Firebase config file

The app crashes at launch without this file.

1. Firebase Console → your project (`dailycfspinstreak`) → ⚙️ **Project settings** → **Your apps** →
   the iOS app → **Download `GoogleService-Info.plist`**.
2. Put it in the inner source folder, next to `ContentView.swift`:
   ```
   DailyCFSpinStreak_MobileComputing/
   ├── DailyCFSpinStreak.xcodeproj
   └── DailyCFSpinStreak/
       ├── ContentView.swift
       └── GoogleService-Info.plist   ← here
   ```
   The project uses a synchronized folder, so Xcode adds it to the app automatically. If you are
   unsure, select the file in Xcode, open the right-hand panel (⌥⌘1), and check that
   **Target Membership → DailyCFSpinStreak** is ticked.

## Step 4: Check the Firebase console (one time only)

| Where | What to do |
|---|---|
| **Authentication → Sign-in method** | **Email/Password** = Enabled |
| **Firestore Database** | The database exists (any region) |
| **Firestore → Rules** | Paste the contents of [`firestore.rules`](../firestore.rules) → **Publish** |
| **Project settings → Your apps** | The iOS bundle ID is `com.example.DailyCFSpinStreak` |

## Step 5: Open the project in Xcode

```bash
open DailyCFSpinStreak.xcodeproj
```

Or double-click `DailyCFSpinStreak.xcodeproj` in Finder.

Xcode then **downloads the Firebase Swift packages** automatically. Watch the progress in the top
bar or in the left sidebar under *Package Dependencies*. The first time can take several minutes.
Wait until it finishes.

If package download fails: **File → Packages → Reset Package Caches**, then
**File → Packages → Resolve Package Versions**.

## Step 6: Run in the iPhone Simulator

1. At the top of Xcode, set the **scheme** to `DailyCFSpinStreak` and pick a **simulator** such as
   *iPhone 16* (iOS 18 or newer).
2. Press **⌘R** (or the ▶︎ Run button).
3. The Simulator opens and shows the **Login** screen.

The first build compiles Firebase and takes a few minutes. Later builds are fast.

## Step 7 (optional): Run on a real iPhone

1. Connect the iPhone with a cable and tap **Trust** on the phone.
2. On the iPhone, turn on **Settings → Privacy & Security → Developer Mode** and restart.
3. In Xcode, click the blue project icon → target **DailyCFSpinStreak** → **Signing & Capabilities**:
   - Tick **Automatically manage signing**.
   - **Team:** add your Apple ID (Xcode → Settings → Accounts) and select it.
   - If Xcode says the bundle ID is taken, change it (for example
     `com.yourname.DailyCFSpinStreak`). Then, in Firebase, **add a new iOS app with that bundle ID**
     and download its new `GoogleService-Info.plist`.
4. Select your iPhone as the run destination and press **⌘R**.
5. The first time, on the iPhone: **Settings → General → VPN & Device Management → trust your
   developer certificate**.

---

## Quick test after it runs

1. **Register:** enter a name, email and password (6+ characters). The Dashboard appears.
2. **Profile:** connect your Codeforces handle. An invalid handle shows an error.
3. **Spin:** pick 800–1000 and tap Spin. The first time it downloads about 10,000 problems from
   Codeforces.
4. **Start Solving:**
   - Start the timer, then tap **Show Hint**. The tags appear.
   - Tap **Open Problem Statement**. The page opens inside the app and the timer keeps running.
5. Solve the problem on codeforces.com with the same handle, then tap **Verify Accepted
   Submission**. The streak becomes 1.
6. **Stop the app and run it again.** You stay logged in.

The full 18-case test list is in section 9 of [PROJECT_GUIDE.md](PROJECT_GUIDE.md).

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Crash at launch: *"Could not locate configuration file GoogleService-Info.plist"* or *FirebaseApp.configure() failed* | The plist is missing or not in the target. Repeat Step 3 |
| Xcode says *"The project … cannot be opened"* or *"unsupported format"* | Your Xcode is older than the project format. See [the project-format note](#important-project-format-note) |
| *Missing package product 'FirebaseAuth'* (or Firestore/Core) | File → Packages → Reset Package Caches, then Resolve Package Versions. Check your internet connection |
| Register fails: *"Missing or insufficient permissions"* | The Firestore rules were not published (Step 4) |
| Register fails: *"operation not allowed"* or *CONFIGURATION_NOT_FOUND* | Email/Password sign-in is not enabled (Step 4) |
| *"The database (default) does not exist"* | Create the Firestore database (Step 4) |
| *"Could not reach Codeforces"* | No internet, or codeforces.com is down. Try again later |
| *"Too many requests to Codeforces"* | Codeforces allows about 1 request every 2 seconds. Wait a few seconds |
| Spin says *"No problem matches these filters"* | Widen the rating range or select fewer topics (a problem must have all selected tags) |
| Verify says *"No Accepted submission found"* | The Accepted solution must be from the same handle as in Profile and for the same problem (contest + index) |
| Build error about **concurrency / Sendable / MainActor** | Usually a warning. If it is an error: target → Build Settings → search **"Strict Concurrency"** → set it to **Minimal**. If it still fails, copy the error text from the Issue Navigator (⌘5) |
| Any other build error | Open the Issue Navigator (⌘5), click the **first** red error, and copy its message and file:line to get help. Later errors are often caused by the first one |
| Simulator is slow or stuck | Simulator menu → Device → Erase All Content and Settings, then run again |

### Viewing logs

Xcode's bottom panel (**⇧⌘Y**) shows the console. Firebase and the app print errors there, for
example *"Could not load solved problems: …"*.

---

## Important: project format note

This project was created with a **recent Xcode** that saves the project in the newer
`project.xcproj` format with synchronized folders. If your Xcode cannot open it, you can still run
the code by making a fresh project:

1. In Xcode: **File → New → Project → iOS → App**.
   - Product Name: `DailyCFSpinStreak`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Untick "Include Tests"
2. Bundle Identifier: `com.example.DailyCFSpinStreak` (or match your Firebase iOS app).
3. Delete the new project's own `ContentView.swift` and `DailyCFSpinStreakApp.swift` (Move to Trash).
4. Drag **everything inside** the repo's `DailyCFSpinStreak/` folder (`Components`, `Models`,
   `Services`, `ViewModels`, `Views`, `ContentView.swift`, `DailyCFSpinStreakApp.swift`, `Assets.xcassets`,
   `GoogleService-Info.plist`) into the new project. Choose **Copy items if needed** and
   **Create groups**, and make sure the app target is ticked.
5. **File → Add Package Dependencies…** → `https://github.com/firebase/firebase-ios-sdk` →
   *Up to Next Major* → add **FirebaseAuth**, **FirebaseCore** and **FirebaseFirestore** to the app target.
6. Target → **General → Minimum Deployments → iOS 18.0**.
7. Target → **Build Settings**:
   - Search **"Default Actor Isolation"** and set it to **MainActor**, if the setting exists.
   - Search **"Swift Language Version"** and set it to **Swift 5**.
8. Press **⌘R**.
