//
//  TeacherSettingsView.swift
//  windsurf classroom app
//
//  Created by Cascade on 2026/05/03.
//

import SwiftUI

struct TeacherSettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                            .accessibilityLabel("Profile icon")
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.name ?? "Teacher")
                                .font(.headline)
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    Button(role: .destructive) {
                        Task {
                            await authViewModel.logout()
                            dismiss()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityIdentifier("teacher-settings-sign-out")
                    .accessibilityLabel("Sign out")
                    .accessibilityHint("Logs out of your account")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Done")
                }
            }
        }
    }
}

#Preview {
    TeacherSettingsView()
        .environmentObject(AuthViewModel())
}
