//
//  StudentService.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation

@MainActor
class StudentService {
    private let supabaseService = SupabaseService.shared
    
    func fetchStudents(classId: UUID) async throws -> [Student] {
        return try await supabaseService.fetchStudents(classId: classId)
    }
    
    func fetchStudent(id: UUID) async throws -> Student {
        return try await supabaseService.fetchStudent(id: id)
    }
    
    func createStudent(_ student: Student) async throws {
        try await supabaseService.createStudent(student)
    }
    
    func updateStudentPoints(studentId: UUID, newTotal: Int) async throws {
        try await supabaseService.updateStudentPoints(studentId: studentId, newTotal: newTotal)
    }
}
