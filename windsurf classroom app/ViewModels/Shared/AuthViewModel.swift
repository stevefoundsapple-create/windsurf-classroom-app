//
//  AuthViewModel.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation
import Combine
import SwiftUI
import os.log
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    private let authService = AuthService()
    private let logger = Logger(subsystem: "ClassroomApp", category: "Auth")
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: UserProfile?
    
    init() {
        checkExistingSession()
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await authService.signIn(email: email, password: password)
            logger.info("Sign in successful for user: \(session.user.id)")
            
            let userId = session.user.id
            let profile = try await authService.fetchProfile(userId: userId)
            logger.info("Profile fetched successfully for role: \(profile.role.rawValue)")
            currentUser = profile
            
            // Register for push notifications if user is a parent
            if profile.role == .parent {
                await NotificationService.shared.registerForPushNotifications()
            }
        } catch let error as Auth.AuthError {
            logger.error("Auth error during sign in: \(error.localizedDescription)")
            errorMessage = "Unable to sign in. Please check your email and password and try again."
        } catch let error as PostgrestError {
            logger.error("Database error during profile fetch: \(error.message)")
            errorMessage = "Signed in but failed to load profile. Please contact support."
        } catch {
            logger.error("Unexpected error during sign in: \(String(describing: error))")
            errorMessage = "Unable to sign in. Please check your email and password and try again."
        }
        
        isLoading = false
    }
    
    func logout() async {
        // Unregister device token if user is a parent
        if currentUser?.role == .parent {
            await NotificationService.shared.unregisterDeviceToken()
        }
        
        do {
            try await authService.signOut()
            currentUser = nil
        } catch {
            errorMessage = "Logout failed: \(error.localizedDescription)"
        }
    }
    
    private func checkExistingSession() {
        Task {
            do {
                guard let session = try await authService.currentSession() else {
                    return
                }
                let userId = session.user.id

                let profile = try await authService.fetchProfile(userId: userId)
                currentUser = profile

                // Register for push notifications if user is a parent
                if profile.role == .parent {
                    await NotificationService.shared.registerForPushNotifications()
                }
            } catch Auth.AuthError.sessionMissing {
                // No active session - user needs to log in, this is expected
                logger.debug("No existing session found")
            } catch {
                logger.error("Failed to fetch existing user profile: \(error.localizedDescription)")
            }
        }
    }
}
