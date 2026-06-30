//
//  LoginView.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo/Title
            VStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .accessibilityLabel("Classroom Behavior app logo")
                
                Text("Classroom Behavior")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Track behavior in real-time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Login Form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .accessibilityIdentifier("login-email-field")
                    .accessibilityLabel("Email address")
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityIdentifier("login-password-field")
                    .accessibilityLabel("Password")
                
                Button(action: {
                    Task {
                        await authViewModel.login(email: email, password: password)
                    }
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(email.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                .accessibilityIdentifier("login-sign-in-button")
                .accessibilityLabel("Sign in")
                .accessibilityHint("Authenticates with your email and password")
            }
            
            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityIdentifier("login-error-message")
            }
            
            Spacer()
        }
        .padding()
        .navigationBarHidden(true)
    }
}
