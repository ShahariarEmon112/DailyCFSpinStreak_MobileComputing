//
//  FormField.swift
//  DailyCFSpinStreak
//
//  A visible label above an input (TextField / SecureField).
//  Generic over `Content` so any input view can be placed inside.
//

import SwiftUI

struct FormField<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 20)
                    .accessibilityHidden(true)
                content
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
        }
    }
}

#Preview {
    FormField(title: "Email", systemImage: "envelope") {
        TextField("you@example.com", text: .constant(""))
    }
    .padding()
    .background(Theme.background)
}
