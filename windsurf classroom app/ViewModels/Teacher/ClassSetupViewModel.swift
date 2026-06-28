//
//  ClassSetupViewModel.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/08.
//

import Foundation
import Combine
import Supabase
import os.log

@MainActor
class ClassSetupViewModel: ObservableObject {
    private let supabaseService = SupabaseService.shared
    private let logger = Logger(subsystem: "ClassroomApp", category: "ClassSetup")
    
    @Published var className: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var generatedClassCode: String?
    
    var canSubmit: Bool {
        !className.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }
    
    /// Generates a unique 6-character alphanumeric class code
    private func generateClassCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
    
    /// Creates a new class for the currently authenticated teacher
    func createClass() async -> UUID? {
        isLoading = true
        errorMessage = nil
        
        do {
            let trimmedName = className.trimmingCharacters(in: .whitespaces)
            
            guard !trimmedName.isEmpty else {
                errorMessage = "Please enter a class name"
                isLoading = false
                return nil
            }
            
            // Get the current authenticated user ID directly from auth session
            // This ensures it matches auth.uid() for the RLS policy
            guard let session = try? await supabaseService.auth.session else {
                logger.error("No active session found when creating class")
                errorMessage = "Authentication error. Please sign in again."
                isLoading = false
                return nil
            }
            
            let teacherId = session.user.id
            let classCode = generateClassCode()
            
            logger.info("Session user ID: \(teacherId.uuidString.lowercased())")
            logger.info("Auth user ID (from session): \(session.user.id.uuidString.lowercased())")
            
            let newClass = Class(
                id: UUID(),
                teacherId: teacherId,
                name: trimmedName,
                classCode: classCode
            )
            
            logger.info("Creating class with teacher_id: \(teacherId.uuidString.lowercased())")
            
            do {
                // Try direct insert first
                try await supabaseService.createClass(newClass)
                logger.info("Created class via direct insert")
            } catch let error as PostgrestError {
                // If RLS fails, try RPC method as fallback
                logger.warning("Direct insert failed: \(error.message), trying RPC fallback...")
                try await supabaseService.createClassViaRPC(newClass)
                logger.info("Created class via RPC fallback")
            }
            
            logger.info("Created class '\(trimmedName)' for teacher: \(teacherId.uuidString.lowercased())")
            
            // Update teacher's profile with the new classId
            do {
                try await supabaseService.updateProfileClassId(userId: teacherId, classId: newClass.id)
                logger.info("Updated teacher profile with classId: \(newClass.id)")
            } catch {
                logger.error("Failed to update teacher profile with classId: \(error.localizedDescription)")
                // Don't fail the entire operation if profile update fails
            }
            
            generatedClassCode = classCode
            isLoading = false
            return newClass.id
            
        } catch let error as PostgrestError {
            logger.error("PostgrestError - Failed to create class: \(error.message)")
            errorMessage = "Database error: \(error.message)"
            isLoading = false
            return nil
        } catch {
            logger.error("Failed to create class: \(error.localizedDescription)")
            errorMessage = "Failed to create class. Please try again."
            isLoading = false
            return nil
        }
    }
}
