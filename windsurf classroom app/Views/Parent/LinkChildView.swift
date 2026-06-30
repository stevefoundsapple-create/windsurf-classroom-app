//
//  LinkChildView.swift
//  windsurf classroom app
//
//  Created by Cascade on 2026/05/03.
//

import SwiftUI

struct LinkChildView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LinkChildViewModel()
    @State private var showSuccessAlert = false
    
    var onLinked: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Section
                    searchSection
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    
                    if viewModel.isSearching {
                        searchingSkeletonView
                            .padding(.top, 40)
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                    } else if !viewModel.searchResults.isEmpty {
                        resultsList
                    } else if viewModel.studentName.isEmpty {
                        emptyStateView
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Link Your Child")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }
            }
            .alert("Confirm Link", isPresented: $viewModel.showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Link", role: .none) {
                    Task {
                        guard let parentId = authViewModel.currentUser?.id else {
                            viewModel.errorMessage = "Not authenticated".localized()
                            return
                        }
                        
                        let success = await viewModel.performLink(parentId: parentId)
                        if success {
                            showSuccessAlert = true
                        }
                    }
                }
            } message: {
                if let student = viewModel.selectedStudent {
                    Text("Are you sure you want to link to \(student.name)?")
                }
            }
            .alert("Success!", isPresented: $showSuccessAlert) {
                Button("Done") {
                    onLinked?()
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage ?? "Successfully linked to your child.")
            }
        }
    }
    
    private var searchSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Child's Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextField("Enter your child's full name", text: $viewModel.studentName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .textContentType(.name)
                    .accessibilityLabel("Child's name")
            }
            
            Button(action: {
                Task {
                    await viewModel.searchStudents()
                }
            }) {
                HStack {
                    if viewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    Text("Search")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(viewModel.studentName.isEmpty ? Color.gray : Color.blue)
                )
            }
            .disabled(viewModel.studentName.isEmpty || viewModel.isSearching)
            .accessibilityLabel("Search")
            .accessibilityHint("Searches for matching students")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Text("Select your child:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                
                ForEach(viewModel.searchResults) { student in
                    studentRow(student)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private func studentRow(_ student: Student) -> some View {
        Button(action: {
            viewModel.selectStudent(student)
        }) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 52, height: 52)
                    
                    Text(String(student.name.prefix(1)).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(student.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Student ID: \(student.id.uuidString.prefix(8).uppercased())...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(student.name), student ID \(student.id)")
        .accessibilityHint("Tap to link this student")
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(.largeTitle))
                .foregroundColor(.orange)
                .accessibilityLabel("Error")
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            Button("Try Again") {
                viewModel.errorMessage = nil
                viewModel.studentName = ""
                viewModel.searchResults = []
            }
            .foregroundColor(.blue)
            .accessibilityLabel("Try again")
        }
        .padding(.top, 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(.largeTitle))
                .foregroundColor(.blue.opacity(0.6))
                .accessibilityLabel("Link child")
            
            Text("Enter your child's name to find and link their account.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 60)
    }
    
    private var searchingSkeletonView: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                StudentSearchSkeletonRow()
            }
        }
    }
}

// MARK: - Student Search Skeleton Row

struct StudentSearchSkeletonRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Skeleton avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 52, height: 52)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.1),
                                    Color.gray.opacity(0.3),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: isAnimating ? .leading : .trailing,
                                endPoint: isAnimating ? .trailing : .leading
                            )
                        )
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                )
                .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                // Skeleton name
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.1),
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.1)
                                    ],
                                    startPoint: isAnimating ? .leading : .trailing,
                                    endPoint: isAnimating ? .trailing : .leading
                                )
                            )
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                    )
                    .clipped()
                
                // Skeleton ID
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.1),
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.1)
                                    ],
                                    startPoint: isAnimating ? .leading : .trailing,
                                    endPoint: isAnimating ? .trailing : .leading
                                )
                            )
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                    )
                    .clipped()
            }
            
            Spacer()
            
            // Skeleton chevron
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 20, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.1),
                                    Color.gray.opacity(0.3),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: isAnimating ? .leading : .trailing,
                                endPoint: isAnimating ? .trailing : .leading
                            )
                        )
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                )
                .clipped()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    LinkChildView()
        .environmentObject(AuthViewModel())
}
