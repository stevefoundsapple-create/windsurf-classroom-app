//
//  AuthService.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation
import Supabase
import os.log

class AuthService: AuthServiceProtocol {
    private let supabaseService: SupabaseServiceProtocol
    private let logger = Logger(subsystem: "ClassroomApp", category: "AuthService")
    
    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }
    
    func signIn(email: String, password: String) async throws -> Session {
        logger.info("Attempting sign in for email: \(email)")
        do {
            let session = try await supabaseService.signIn(email: email, password: password)
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
        try await supabaseService.signOut()
    }
    
    func fetchProfile(userId: UUID) async throws -> UserProfile {
        return try await supabaseService.fetchProfile(userId: userId)
    }
    
    func currentSession() async throws -> Session? {
        return try await supabaseService.getCurrentSession()
    }
    
    func currentUser() async throws -> User? {
        return try await supabaseService.getCurrentSession()?.user
    }
}
