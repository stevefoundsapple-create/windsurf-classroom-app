//
//  LogBehaviorViewModel.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation
import Combine
import os.log

@MainActor
class LogBehaviorViewModel: ObservableObject {
    private let behaviorService = BehaviorService()
    private let categoryService = CategoryService()
    private let logger = Logger(subsystem: "ClassroomApp", category: "LogBehavior")
    
    @Published var categories: [BehaviorCategory] = []
    @Published var selectedCategory: BehaviorCategory?
    @Published var isPositive: Bool = true
    @Published var note: String = ""
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var isLoadingCategories: Bool = false
    
    // Teacher and class IDs from the current user session
    private let teacherId: UUID
    private let classId: UUID
    
    // Callback for optimistic UI updates
    var onOptimisticUpdate: ((UUID, Int) -> Void)?
    
    init(teacherId: UUID, classId: UUID) {
        self.teacherId = teacherId
        self.classId = classId
        fetchCategories()
    }
    
    func fetchCategories() {
        Task {
            await performFetchCategories()
        }
    }
    
    private func performFetchCategories() async {
        isLoadingCategories = true
        
        do {
            let allCategories = try await categoryService.fetchCategories(classId: classId)
            categories = allCategories.filter { $0.isPositive == isPositive }
        } catch {
            // Provide user-friendly error message without exposing raw Supabase errors
            errorMessage = "Unable to load categories. Using default options."
            // Fall back to default categories
            categories = isPositive ? 
                BehaviorCategory.defaultPositiveCategories : 
                BehaviorCategory.defaultNegativeCategories
        }
        
        isLoadingCategories = false
    }
    
    func toggleBehaviorType() {
        isPositive.toggle()
        selectedCategory = nil
        fetchCategories()
    }
    
    func selectCategory(_ category: BehaviorCategory) {
        selectedCategory = category
    }
    
    func logEvent(for student: Student) async {
        guard let selectedCategory = selectedCategory else {
            errorMessage = "Please select a behavior category"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        logger.info("Attempting to log behavior event - studentId: \(student.id), teacherId: \(self.teacherId), classId: \(self.classId)")
        
        // Optimistic UI update - update the student's points immediately
        let newPointTotal = student.pointTotal + selectedCategory.points
        onOptimisticUpdate?(student.id, newPointTotal)
        
        do {
            try await behaviorService.logEvent(
                studentId: student.id,
                teacherId: teacherId,
                category: selectedCategory.label,
                isPositive: selectedCategory.isPositive,
                points: selectedCategory.points,
                note: note.isEmpty ? nil : note
            )
            
            logger.info("Successfully logged behavior event for student: \(student.name)")
            
            // Reset form after successful submission
            resetForm()
            
        } catch {
            logger.error("Failed to log behavior event: \(error.localizedDescription)")
            // Provide user-friendly error message without exposing raw Supabase errors
            errorMessage = "Unable to log behavior. Please check your connection and try again."
            // Rollback optimistic update on error
            onOptimisticUpdate?(student.id, student.pointTotal)
        }
        
        isSubmitting = false
    }
    
    private func resetForm() {
        selectedCategory = nil
        note = ""
        errorMessage = nil
    }
    
    var canSubmit: Bool {
        return selectedCategory != nil && !isSubmitting
    }
}
