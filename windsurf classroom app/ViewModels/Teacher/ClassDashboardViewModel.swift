//
//  ClassDashboardViewModel.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation
import Combine
import Supabase
import os.log

@MainActor
class ClassDashboardViewModel: ObservableObject {
    private let studentService = StudentService()
    private let supabaseService = SupabaseService.shared
    private let logger = Logger(subsystem: "ClassroomApp", category: "ClassDashboard")
    
    @Published var students: [Student] = []
    @Published var isLoading: Bool = true
    @Published var selectedStudent: Student?
    @Published var errorMessage: String?
    @Published var classCode: String?
    
    private var classId: UUID?
    private var teacherId: UUID?
    
    init(classId: UUID?, teacherId: UUID? = nil) {
        self.classId = classId
        self.teacherId = teacherId
        // Only fetch students if we have a valid classId
        if classId != nil {
            fetchStudents()
            fetchClassCode()
        } else if teacherId != nil {
            // Fallback: try to fetch class by teacherId
            fetchClassByTeacherId()
        } else {
            // Don't show loading state if we don't have a classId yet
            isLoading = false
        }
    }
    
    func fetchStudents() {
        Task {
            await performFetch()
        }
    }
    
    private func performFetch() async {
        isLoading = true
        errorMessage = nil
        
        guard let classId = classId else {
            errorMessage = "No classroom assigned. Please contact support."
            isLoading = false
            students = []
            return
        }
        
        do {
            students = try await studentService.fetchStudents(classId: classId)
        } catch {
            // Provide user-friendly error message without exposing raw Supabase errors
            errorMessage = "Unable to load students. Please check your connection and try again."
            students = []
        }
        
        isLoading = false
    }
    
    func selectStudent(_ student: Student) {
        selectedStudent = student
    }
    
    func refreshStudents() {
        fetchStudents()
    }
    
    func fetchClassCode() {
        Task {
            await performFetchClassCode()
        }
    }
    
    private func performFetchClassCode() async {
        guard let classId = classId else { return }
        
        do {
            let classObj = try await supabaseService.fetchClass(id: classId)
            classCode = classObj.classCode
        } catch {
            logger.error("Failed to fetch class code: \(error.localizedDescription)")
        }
    }
    
    func updateStudentPoints(studentId: UUID, newPoints: Int) {
        if let index = students.firstIndex(where: { $0.id == studentId }) {
            students[index].pointTotal = newPoints
        }
    }
    
    func updateClassId(_ newClassId: UUID?) {
        // Only update and re-fetch if the classId has changed
        if classId != newClassId {
            self.classId = newClassId
            if newClassId != nil {
                fetchStudents()
                fetchClassCode()
            } else {
                // Clear state if classId is removed
                students = []
                errorMessage = nil
                isLoading = false
                classCode = nil
            }
        }
    }
    
    func updateTeacherId(_ newTeacherId: UUID?) {
        self.teacherId = newTeacherId
    }
    
    private func fetchClassByTeacherId() {
        Task {
            await performFetchClassByTeacherId()
        }
    }
    
    private func performFetchClassByTeacherId() async {
        guard let teacherId = teacherId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let classObj = try await supabaseService.fetchClassByTeacherId(teacherId: teacherId) {
                // Update classId and fetch students
                self.classId = classObj.id
                self.classCode = classObj.classCode
                fetchStudents()
                
                // Update the teacher's profile with the classId for future logins
                do {
                    try await supabaseService.updateProfileClassId(userId: teacherId, classId: classObj.id)
                    logger.info("Updated teacher profile with classId: \(classObj.id)")
                } catch {
                    logger.error("Failed to update teacher profile with classId: \(error.localizedDescription)")
                }
            } else {
                // No class found for this teacher
                isLoading = false
                students = []
            }
        } catch {
            logger.error("Failed to fetch class by teacherId: \(error.localizedDescription)")
            errorMessage = "Unable to load classroom. Please check your connection and try again."
            isLoading = false
            students = []
        }
    }
}
