//
//  AuthService.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation
import Supabase
import os.log

class AuthService {
    private let supabaseService = SupabaseService.shared
    private let logger = Logger(subsystem: "ClassroomApp", category: "AuthService")
    
    func signIn(email: String, password: String) async throws -> Session {
        logger.info("Attempting sign in for email: \(email)")
        do {
            let session = try await supabaseService.auth.signIn(
                email: email,
                password: password
            )
            logger.info("Sign in successful for user: \(session.user.id)")
            return session
        } catch let error as Auth.AuthError {
            let errorCode = (error as NSError).code
            logger.error("Supabase auth error [code: \(errorCode)]: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("Unexpected error during sign in: \(String(describing: error))")
            throw error
        }
    }
    
    func signOut() async throws {
        try await supabaseService.auth.signOut()
    }
    
    func fetchProfile(userId: UUID) async throws -> UserProfile {
        return try await supabaseService.fetchProfile(userId: userId)
    }
    
    func currentSession() async throws -> Session? {
        return try await supabaseService.auth.session
    }
    
    func currentUser() async throws -> User? {
        return try await supabaseService.auth.session.user
    }
}
