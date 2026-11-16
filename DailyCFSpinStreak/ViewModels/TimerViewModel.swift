//
//  TimerViewModel.swift
//  DailyCFSpinStreak
//
//  Stopwatch for solving a problem: start, pause, resume, finish.
//
//  How the time is measured:
//  We do NOT just add +1 every second (ticks can be missed when the app is
//  in the background). Instead we store
//      accumulatedSeconds  = time from earlier running periods
//      runningSince        = the Date when the current period started
//  and compute: elapsed = accumulated + (now - runningSince).
//  The 1-second loop only refreshes the label on screen.
//
//  This object is created once in MainTabView (@StateObject), so the timer
//  is not reset when the user navigates between screens.
//

import Foundation
import Combine

final class TimerViewModel: ObservableObject {
    @Published private(set) var elapsedSeconds = 0
    @Published private(set) var isRunning = false
    @Published private(set) var hasStarted = false
    /// True once the user tapped "Show Hint" for the current problem.
    @Published private(set) var hintUsed = false
    /// Explains an automatic pause, e.g. "Paused because you left the app."
    @Published private(set) var autoPauseReason: String?

    /// The problem this timer belongs to (so opening another problem starts fresh).
    private(set) var activeProblemId: String?

    private var accumulatedSeconds: TimeInterval = 0
    private var runningSince: Date?
    private var tickTask: Task<Void, Never>?

    /// Shown on the timer label, e.g. "05:42".
    var formattedTime: String { DisplayFormat.duration(elapsedSeconds) }

    // MARK: - Lifecycle of one solve

    /// Call when a problem screen appears. Resets only if it is a different problem.
    func prepare(for problem: Problem) {
        guard activeProblemId != problem.id else { return }
        reset()
        activeProblemId = problem.id
    }

    func start() {
        guard !isRunning else { return }
        autoPauseReason = nil
        hasStarted = true
        isRunning = true
        runningSince = Date()
        startTicking()
    }

    func pause() {
        guard isRunning, let runningSince else { return }
        accumulatedSeconds += Date().timeIntervalSince(runningSince)
        self.runningSince = nil
        isRunning = false
        stopTicking()
        updateElapsed()
    }

    func resume() {
        start()
    }

    /// Pause caused by the app (leaving the screen, app going to background),
    /// not by the user. Remembers the reason so the screen can explain it.
    func pauseAutomatically(reason: String) {
        guard isRunning else { return }
        pause()
        autoPauseReason = reason
    }

    /// Stops the timer and returns the total solving time in seconds.
    /// The problem and hint state are kept, only the clock goes back to 0.
    func finish() -> Int {
        pause()
        let total = elapsedSeconds
        clearTime()
        return total
    }

    func useHint() {
        hintUsed = true
    }

    /// Full reset: clock, hint and problem (used when a different problem opens).
    func reset() {
        clearTime()
        hintUsed = false
        activeProblemId = nil
    }

    private func clearTime() {
        stopTicking()
        autoPauseReason = nil
        accumulatedSeconds = 0
        runningSince = nil
        elapsedSeconds = 0
        isRunning = false
        hasStarted = false
    }

    // MARK: - Screen refresh loop (async/await)

    private func startTicking() {
        stopTicking()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.updateElapsed()
            }
        }
    }

    private func stopTicking() {
        tickTask?.cancel()
        tickTask = nil
    }

    private func updateElapsed() {
        var total = accumulatedSeconds
        if let runningSince {
            total += Date().timeIntervalSince(runningSince)
        }
        elapsedSeconds = Int(total)
    }
}
