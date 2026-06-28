//
//  StudentSetupViewModel.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/08.
//

import Foundation
import Combine
import Supabase
import os.log

@MainActor
class StudentSetupViewModel: ObservableObject {
    private let supabaseService = SupabaseService.shared
    private let logger = Logger(subsystem: "ClassroomApp", category: "StudentSetup")
    
    @Published var name: String = ""
    @Published var classCode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isComplete: Bool = false
    
    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !classCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading
    }
    
    /// Creates a new student profile for the current user
    func createStudentProfile(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespaces)
            let trimmedCode = classCode.trimmingCharacters(in: .whitespaces).uppercased()
            
            guard !trimmedName.isEmpty else {
                errorMessage = "Please enter your name"
                isLoading = false
                return
            }
            
            guard !trimmedCode.isEmpty else {
                errorMessage = "Please enter a class code"
                isLoading = false
                return
            }
            
            // Look up class by code
            guard let classObj = try await supabaseService.fetchClassByCode(trimmedCode) else {
                errorMessage = "Invalid class code. Please check with your teacher."
                isLoading = false
                return
            }
            
            let classId = classObj.id
            
            let newStudent = Student(
                id: UUID(),
                userId: userId,
                name: trimmedName,
                classId: classId,
                parentId: nil,
                pointTotal: 0
            )
            
            do {
                // Try direct insert first
                try await supabaseService.createStudent(newStudent)
                logger.info("Created student profile via direct insert")
            } catch let error as PostgrestError {
                // If RLS fails, try RPC method as fallback
                logger.warning("Direct insert failed: \(error.message), trying RPC fallback...")
                try await supabaseService.createStudentViaRPC(newStudent)
                logger.info("Created student profile via RPC fallback")
            }
            
            logger.info("Created student profile for user: \(userId)")
            isComplete = true
            
        } catch {
            logger.error("Failed to create student profile: \(error.localizedDescription)")
            errorMessage = "Failed to create profile. Please check your class code and try again."
        }
        
        isLoading = false
    }
}
