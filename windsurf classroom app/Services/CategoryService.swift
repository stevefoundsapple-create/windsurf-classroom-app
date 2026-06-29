//
//  CategoryService.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation

class CategoryService: CategoryServiceProtocol {
    private let supabaseService: SupabaseServiceProtocol
    
    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }
    
    func fetchCategories(classId: UUID) async throws -> [BehaviorCategory] {
        do {
            let categories = try await supabaseService.fetchBehaviorCategories(classId: classId)
            
            // If no categories exist for this class, create default ones
            if categories.isEmpty {
                try await createDefaultCategories(for: classId)
                return try await supabaseService.fetchBehaviorCategories(classId: classId)
            }
            
            return categories
        } catch {
            // If there's an error fetching, fall back to default categories
            return BehaviorCategory.defaultPositiveCategories + BehaviorCategory.defaultNegativeCategories
        }
    }
    
    func createCategory(_ category: BehaviorCategory) async throws {
        try await supabaseService.createBehaviorCategory(category)
    }
    
    func updateCategory(_ category: BehaviorCategory) async throws {
        try await supabaseService.updateBehaviorCategory(category)
    }
    
    func deleteCategory(id: UUID) async throws {
        try await supabaseService.deleteBehaviorCategory(id: id)
    }
    
    private func createDefaultCategories(for classId: UUID) async throws {
        let positiveCategories = BehaviorCategory.defaultPositiveCategories.map { category in
            BehaviorCategory(
                id: UUID(),
                classId: classId,
                label: category.label,
                isPositive: category.isPositive,
                points: category.points
            )
        }
        
        let negativeCategories = BehaviorCategory.defaultNegativeCategories.map { category in
            BehaviorCategory(
                id: UUID(),
                classId: classId,
                label: category.label,
                isPositive: category.isPositive,
                points: category.points
            )
        }
        
        let allCategories = positiveCategories + negativeCategories
        
        for category in allCategories {
            try await supabaseService.createBehaviorCategory(category)
        }
    }
}
