//
//  AddStudentViewModel.swift
//  windsurf classroom app
//
//  Created by Cascade on 2026/06/17.
//

import Foundation
import Combine
import os.log

@MainActor
class AddStudentViewModel: ObservableObject {
    private let studentService = StudentService()
    private let logger = Logger(subsystem: "ClassroomApp", category: "AddStudent")
    
    @Published var studentName: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let classId: UUID
    
    init(classId: UUID) {
        self.classId = classId
    }
    
    var canSubmit: Bool {
        !studentName.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }
    
    /// Adds a new student to the class
    func addStudent() async -> Bool {
        let trimmedName = studentName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return false }
        
        isLoading = true
        errorMessage = nil
        
        let newStudent = Student(
            id: UUID(),
            userId: nil,
            name: trimmedName,
            classId: classId,
            parentId: nil,
            pointTotal: 0
        )
        
        do {
            try await studentService.createStudent(newStudent)
            logger.info("Successfully added student: \(trimmedName)")
            studentName = ""
            isLoading = false
            return true
        } catch {
            logger.error("Failed to add student: \(error.localizedDescription)")
            errorMessage = "Failed to add student. Please try again."
            isLoading = false
            return false
        }
    }
    
    func reset() {
        studentName = ""
        errorMessage = nil
        isLoading = false
    }
}
