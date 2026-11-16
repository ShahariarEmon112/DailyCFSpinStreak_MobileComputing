//
//  SolveTimerView.swift
//  DailyCFSpinStreak
//
//  The stopwatch card: big time label + Start / Pause / Resume / Finish.
//  It only displays the TimerViewModel and calls its functions.
//

import SwiftUI

struct SolveTimerView: View {
    @ObservedObject var timerVM: TimerViewModel
    /// Called when the user taps Finish (the parent screen saves the result).
    let onFinish: () -> Void

    private var statusText: String {
        if timerVM.isRunning { return "Running" }
        return timerVM.hasStarted ? "Paused" : "Not started"
    }

    private var statusColor: Color {
        if timerVM.isRunning { return Theme.primary }
        return timerVM.hasStarted ? Theme.streak : Theme.textSecondary
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Solve Timer", systemImage: "timer")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                TagChip(text: statusText, color: statusColor)
            }

            Text(timerVM.formattedTime)
                .font(.system(size: 52, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Elapsed time \(timerVM.formattedTime)")

            if let reason = timerVM.autoPauseReason {
                Label(reason, systemImage: "pause.circle")
                    .font(.footnote)
                    .foregroundStyle(Theme.streak)
            }

            HStack(spacing: 12) {
                if !timerVM.hasStarted {
                    PrimaryButton(title: "Start", systemImage: "play.fill") {
                        timerVM.start()
                    }
                } else {
                    if timerVM.isRunning {
                        PrimaryButton(title: "Pause", systemImage: "pause.fill", color: Theme.streak) {
                            timerVM.pause()
                        }
                    } else {
                        PrimaryButton(title: "Resume", systemImage: "play.fill") {
                            timerVM.resume()
                        }
                    }
                    PrimaryButton(title: "Finish", systemImage: "flag.checkered", color: Theme.info) {
                        onFinish()
                    }
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    SolveTimerView(timerVM: TimerViewModel(), onFinish: {})
        .padding()
        .background(Theme.background)
        .preferredColorScheme(.dark)
}
