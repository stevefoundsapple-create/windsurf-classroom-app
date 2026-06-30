//
//  ParentSettingsView.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/03.
//

import SwiftUI

struct ParentSettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = ParentSettingsViewModel()
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingLinkChildSheet = false
    @State private var showingUnlinkAlert = false
    @State private var childToUnlink: Student?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                List {
                    // Account Section
                    accountSection
                    
                    // Child Information Section
                    if !viewModel.children.isEmpty {
                        childrenSection
                    } else {
                        linkChildSection
                    }
                    
                    // App Settings Section
                    appSettingsSection
                    
                    // Support Section
                    supportSection
                    
                    // Danger Zone
                    dangerZoneSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                Task {
                    await authViewModel.logout()
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    if let userId = authViewModel.currentUser?.id {
                        do {
                            try await viewModel.deleteAccount(userId: userId)
                            await authViewModel.logout()
                        } catch {
                            // Error message is set in the ViewModel
                        }
                    }
                }
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showingLinkChildSheet) {
            LinkChildView {
                Task {
                    if let parentId = authViewModel.currentUser?.id {
                        await viewModel.fetchChildren(parentId: parentId)
                    }
                }
            }
        }
        .alert("Unlink Child", isPresented: $showingUnlinkAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Unlink", role: .destructive) {
                if let child = childToUnlink {
                    Task {
                        await viewModel.unlinkChild(child)
                    }
                }
            }
        } message: {
            if let child = childToUnlink {
                Text("Are you sure you want to unlink \(child.name)? You will no longer receive notifications for their behavior events.")
            }
        }
        .task {
            if let parentId = authViewModel.currentUser?.id {
                await viewModel.fetchChildren(parentId: parentId)
            }
            if let userId = authViewModel.currentUser?.id {
                await viewModel.fetchNotificationPreferences(userId: userId)
            }
        }
    }
    
    private var accountSection: some View {
        Section("Account") {
            if let user = authViewModel.currentUser {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.purple)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.email)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Parent Account")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            
            Button(action: {
                showingLogoutAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                        .foregroundColor(.red)
                    
                    Text("Log Out")
                        .foregroundColor(.red)
                }
            }
            .accessibilityIdentifier("settings-log-out-button")
            .accessibilityLabel("Log out")
        }
    }
    
    private var childrenSection: some View {
        Section("Child Information") {
            ForEach(viewModel.children) { child in
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(child.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Student ID: \(child.id.uuidString.prefix(8))...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        childToUnlink = child
                        showingUnlinkAlert = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                    .accessibilityLabel("Unlink \(child.name)")
                    .accessibilityHint("Removes the link to this child")
                }
                .padding(.vertical, 4)
                .accessibilityLabel("\(child.name), student")
            }
            
            if viewModel.children.count == 1 {
                Text("Contact your child's teacher if you need to update this information.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
        }
    }
    
    private var linkChildSection: some View {
        Section("Child Information") {
            Button(action: {
                showingLinkChildSheet = true
            }) {
                HStack {
                    Image(systemName: "link.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Link Your Child")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Search for your child to link accounts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .accessibilityLabel("Link your child")
            .accessibilityIdentifier("settings-link-child-button")
        }
    }
    
    private var appSettingsSection: some View {
        Section("App Settings") {
            if let preferences = viewModel.notificationPreferences {
                Toggle(isOn: Binding(
                    get: { preferences.positiveBehaviors },
                    set: { newValue in
                        Task {
                            await viewModel.updatePreference(\.positiveBehaviors, value: newValue)
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Positive Behaviors")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Get notified when your child earns points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
                .accessibilityLabel("Positive Behaviors")
                
                Toggle(isOn: Binding(
                    get: { preferences.negativeBehaviors },
                    set: { newValue in
                        Task {
                            await viewModel.updatePreference(\.negativeBehaviors, value: newValue)
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Negative Behaviors")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Get notified when your child loses points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
                .accessibilityLabel("Negative Behaviors")
                
                Toggle(isOn: Binding(
                    get: { preferences.weeklySummaries },
                    set: { newValue in
                        Task {
                            await viewModel.updatePreference(\.weeklySummaries, value: newValue)
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundColor(.purple)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekly Summaries")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Receive a weekly digest of your child's progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
                .accessibilityLabel("Weekly Summaries")
                
                Toggle(isOn: Binding(
                    get: { preferences.quietHoursEnabled },
                    set: { newValue in
                        Task {
                            await viewModel.updatePreference(\.quietHoursEnabled, value: newValue)
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.indigo)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quiet Hours")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if preferences.quietHoursEnabled {
                                Text("\(preferences.quietHoursStart) - \(preferences.quietHoursEnd)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Disable notifications during specific hours")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .accessibilityLabel("Quiet Hours")
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading preferences...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var supportSection: some View {
        Section("Support") {
            Button(action: {
                if let url = URL(string: "mailto:support@classroomapp.com") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    Text("Contact Support")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .accessibilityLabel("Contact support")
            .accessibilityIdentifier("settings-contact-support")
            
            Button(action: {
                if let url = URL(string: "https://classroomapp.com/privacy") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    Text("Privacy Policy")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .accessibilityLabel("Privacy policy")
            .accessibilityIdentifier("settings-privacy-policy")
            
            Button(action: {
                if let url = URL(string: "https://classroomapp.com/terms") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.purple)
                        .font(.title2)
                    
                    Text("Terms of Service")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .accessibilityIdentifier("settings-terms")
            .accessibilityLabel("Terms of service")
        }
    }
    
    private var dangerZoneSection: some View {
        Section {
                Button(action: {
                    showingDeleteAccountAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        
                        Text("Delete Account")
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .accessibilityIdentifier("settings-delete-account-button")
            .accessibilityLabel("Delete account")
            .accessibilityHint("Permanently deletes your account")
        } header: {
            Text("Danger Zone")
                .foregroundColor(.red)
        }
    }
}

#Preview {
    ParentSettingsView()
        .environmentObject(AuthViewModel())
}
