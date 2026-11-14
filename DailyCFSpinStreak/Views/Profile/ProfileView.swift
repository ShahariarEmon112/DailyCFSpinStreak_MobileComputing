//
//  ProfileView.swift
//  DailyCFSpinStreak
//
//  Account info, Codeforces handle connection and logout.
//  Built with Form + Section (the standard SwiftUI settings layout).
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authVM: AuthenticationViewModel

    @State private var handleInput = ""
    @State private var showLogoutConfirm = false

    private var user: AppUser? { authVM.currentUser }

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Name", value: user?.name ?? "—")
                LabeledContent("Email", value: user?.email ?? "—")
            }
            .listRowBackground(Theme.card)

            Section {
                if let handle = user?.cfHandle {
                    LabeledContent("Connected handle") {
                        Label(handle, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Theme.primary)
                    }
                }
                TextField("Codeforces handle (e.g. tourist)", text: $handleInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    Task { await authVM.connectHandle(handleInput) }
                } label: {
                    HStack {
                        Text(user?.cfHandle == nil ? "Connect Handle" : "Update Handle")
                        if authVM.isLoading {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(handleInput.trimmingCharacters(in: .whitespaces).isEmpty || authVM.isLoading)
            } header: {
                Text("Codeforces")
            } footer: {
                Text("Your handle is used to check for accepted submissions. Only verified solves count toward your streak.")
            }
            .listRowBackground(Theme.card)

            Section {
                Button("Log Out", role: .destructive) {
                    showLogoutConfirm = true
                }
            }
            .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle("Profile")
        .onAppear {
            handleInput = user?.cfHandle ?? ""
        }
        .alert("Log out?", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) { authVM.logout() }
        } message: {
            Text("You can log back in any time. Your data stays saved.")
        }
        .errorAlert($authVM.errorMessage)
    }
}

#Preview {
    let authVM = AuthenticationViewModel()
    authVM.currentUser = SampleData.user
    return NavigationStack {
        ProfileView(authVM: authVM)
    }
    .preferredColorScheme(.dark)
}
