//
//  Theme.swift
//  DailyCFSpinStreak
//
//  One place for every color and text style, so the whole app looks consistent.
//  Change a value here and every screen updates.
//

import SwiftUI

enum Theme {
    // MARK: Colors (dark "coding practice" palette)
    static let background    = Color(hex: 0x0F172A)   // app background (deep navy)
    static let card          = Color(hex: 0x192134)   // card / row background
    static let cardBorder    = Color.white.opacity(0.08)
    static let primary       = Color(hex: 0x22C55E)   // green = success / main actions
    static let streak        = Color(hex: 0xF59E0B)   // amber = streak flame
    static let info          = Color(hex: 0x38BDF8)   // blue = neutral info
    static let danger        = Color(hex: 0xEF4444)   // red = delete / logout / errors
    static let textPrimary   = Color(hex: 0xF8FAFC)
    static let textSecondary = Color(hex: 0x94A3B8)

    // MARK: Layout
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 16

    /// Codeforces-style color for a problem rating (gray → red as difficulty grows).
    static func ratingColor(_ rating: Int?) -> Color {
        guard let rating else { return textSecondary }
        switch rating {
        case ..<1200: return Color(hex: 0xA3A3A3)   // gray
        case ..<1400: return Color(hex: 0x4ADE80)   // green
        case ..<1600: return Color(hex: 0x22D3EE)   // cyan
        case ..<1900: return Color(hex: 0x60A5FA)   // blue
        case ..<2100: return Color(hex: 0xC084FC)   // violet
        case ..<2400: return Color(hex: 0xFB923C)   // orange
        default:      return Color(hex: 0xF87171)   // red
        }
    }
}

// MARK: - Color from a hex number, e.g. Color(hex: 0x22C55E)
extension Color {
    init(hex: UInt32) {
        let red   = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue  = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

// MARK: - Reusable card look as a custom ViewModifier
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    /// Usage: `Text("Hi").cardStyle()`
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    /// Fills the whole screen (behind the safe areas too) with the app background.
    func screenBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background.ignoresSafeArea())
    }

    /// Shows an Alert whenever `message` is not nil, and clears it on "OK".
    /// Usage: `.errorAlert($viewModel.errorMessage)`
    func errorAlert(_ message: Binding<String?>) -> some View {
        let isPresented = Binding<Bool>(
            get: { message.wrappedValue != nil },
            set: { newValue in if !newValue { message.wrappedValue = nil } }
        )
        return alert("Something went wrong", isPresented: isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}

// MARK: - Small formatting helpers used by several screens
enum DisplayFormat {
    /// 125 seconds → "02:05", 3725 seconds → "1:02:05"
    static func duration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Date → "13 Nov 2026"
    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
    }
}
