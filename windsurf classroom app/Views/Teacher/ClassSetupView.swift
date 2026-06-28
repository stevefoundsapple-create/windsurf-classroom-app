//
//  ClassSetupView.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/08.
//

import SwiftUI

struct ClassSetupView: View {
    @StateObject private var viewModel = ClassSetupViewModel()
    let onComplete: (UUID) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let classCode = viewModel.generatedClassCode {
                    successView(classCode: classCode)
                } else {
                    formView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
    
    private var formView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Create Your Classroom")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Give your classroom a name to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Classroom Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Ms. Smith's 3rd Grade", text: $viewModel.className)
                        .textContentType(.organizationName)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                }
            }
            .padding(.horizontal, 24)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Create Button
            Button {
                Task {
                    if let classId = await viewModel.createClass() {
                        onComplete(classId)
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Classroom")
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(viewModel.canSubmit ? Color.blue : Color.gray)
                )
            }
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    private func successView(classCode: String) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                
                Text("Classroom Created!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Share this code with your students")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Class Code Display
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Class Code")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(classCode)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                }
                
                Button {
                    UIPasteboard.general.string = classCode
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Code")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Done Button
            Button {
                onCancel()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.blue)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    ClassSetupView(onComplete: { _ in }, onCancel: {})
}
