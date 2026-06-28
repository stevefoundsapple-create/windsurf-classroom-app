//
//  StudentSetupView.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/08.
//

import SwiftUI

struct StudentSetupView: View {
    @StateObject private var viewModel = StudentSetupViewModel()
    let userId: UUID
    let onComplete: () -> Void
    let onSignOut: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            Button {
                                onSignOut()
                            } label: {
                                Image(systemName: "arrow.right.square")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Complete Your Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Enter your details to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    
                    // Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your full name", text: autoCapitalizeBinding($viewModel.name))
                                .textContentType(.name)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.systemBackground))
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Class Code")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your class code", text: $viewModel.classCode)
                                .textContentType(.none)
                                .autocapitalization(.allCharacters)
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
                    
                    // Submit Button
                    Button {
                        Task {
                            await viewModel.createStudentProfile(userId: userId)
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Get Started")
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
            .navigationBarHidden(true)
            .onChange(of: viewModel.isComplete) { _, isComplete in
                if isComplete {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    StudentSetupView(userId: UUID(), onComplete: {}, onSignOut: {})
}
