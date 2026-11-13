//
//  PrimaryButton.swift
//  DailyCFSpinStreak
//
//  Big full-width button used for the main action on a screen
//  (Login, Spin, Finish...). Shows a spinner while `isLoading` is true.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var color: Color = Theme.primary
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PrimaryLabel(title: title, systemImage: systemImage, color: color, isLoading: isLoading)
        }
        .disabled(isLoading)
    }
}

/// The filled look of PrimaryButton, on its own so a NavigationLink can use it too.
struct PrimaryLabel: View {
    let title: String
    var systemImage: String? = nil
    var color: Color = Theme.primary
    var isLoading: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .tint(Theme.background)
            } else if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, minHeight: 50)   // >= 44pt touch target
        .foregroundStyle(Theme.background)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Outlined version for secondary actions (e.g. "Save to Retry List").
struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var color: Color = Theme.info
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title).fontWeight(.semibold)
            } icon: {
                if let systemImage { Image(systemName: systemImage) }
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .foregroundStyle(color)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.6), lineWidth: 1.5)
            )
        }
    }
}

#Preview {
    VStack {
        PrimaryButton(title: "Spin", systemImage: "dice.fill") {}
        PrimaryButton(title: "Loading", isLoading: true) {}
        SecondaryButton(title: "Save to Retry", systemImage: "bookmark") {}
    }
    .padding()
    .background(Theme.background)
}
