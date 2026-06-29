//
//  LinkChildViewModel.swift
//  windsurf classroom app
//
//  Created by Cascade on 2026/05/03.
//

import Foundation
import Combine
import os.log

@MainActor
class LinkChildViewModel: ObservableObject {
    private let supabaseService: SupabaseServiceProtocol
    private let logger = Logger(subsystem: "ClassroomApp", category: "LinkChild")
    
    @Published var studentName: String = ""
    @Published var classCode: String = ""
    @Published var searchResults: [Student] = []
    @Published var isSearching: Bool = false
    @Published var isLinking: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showConfirmation: Bool = false
    @Published var selectedStudent: Student?
    
    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }
    
    /// Searches for students matching the entered name within a class
    func searchStudents() async {
        guard !studentName.isEmpty else {
            errorMessage = "Please enter your child's name"
            return
        }
        
        isSearching = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Search by name (case-insensitive partial match)
            searchResults = try await supabaseService.searchStudentsByName(studentName)
            
            if searchResults.isEmpty {
                errorMessage = "No students found with that name. Please check the spelling or contact your child's teacher."
            }
            
        } catch {
            logger.error("Failed to search students: \(error.localizedDescription)")
            errorMessage = "Unable to search. Please check your connection and try again."
        }
        
        isSearching = false
    }
    
    /// Selects a student and shows confirmation
    func selectStudent(_ student: Student) {
        selectedStudent = student
        showConfirmation = true
    }
    
    /// Links the parent to the selected student
    func linkParentToStudent(parentId: UUID) async -> Bool {
        guard let student = selectedStudent else {
            errorMessage = "No student selected"
            return false
        }
        
        isLinking = true
        errorMessage = nil
        
        do {
            try await supabaseService.linkParentToStudent(parentId: parentId, studentId: student.id)
            
            logger.info("Successfully linked parent \(parentId) to student \(student.id)")
            successMessage = "Successfully linked to \(student.name)!"
            isLinking = false
            return true
            
        } catch {
            logger.error("Failed to link parent to student: \(error.localizedDescription)")
            errorMessage = "Unable to link to student. They may already be linked to another parent account."
            isLinking = false
            return false
        }
    }
    
    /// Performs the link operation with the given parent ID
    func performLink(parentId: UUID) async -> Bool {
        return await linkParentToStudent(parentId: parentId)
    }
    
    /// Resets the search
    func reset() {
        studentName = ""
        classCode = ""
        searchResults = []
        errorMessage = nil
        successMessage = nil
        selectedStudent = nil
        showConfirmation = false
    }
}
