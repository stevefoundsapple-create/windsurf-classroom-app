import Foundation

class CategoryService: CategoryServiceProtocol {
    private let supabaseService: SupabaseServiceProtocol
    private let cache: OfflineCacheService
    
    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared, cache: OfflineCacheService = .shared) {
        self.supabaseService = supabaseService
        self.cache = cache
    }
    
    func fetchCategories(classId: UUID) async throws -> [BehaviorCategory] {
        let key = "categories_\(classId)"
        
        if let cached: [BehaviorCategory] = cache.fetch([BehaviorCategory].self, key: key) {
            return cached
        }
        
        do {
            let categories = try await supabaseService.fetchBehaviorCategories(classId: classId)
            
            if categories.isEmpty {
                try await createDefaultCategories(for: classId)
                let created = try await supabaseService.fetchBehaviorCategories(classId: classId)
                cache.cache(created, key: key)
                return created
            }
            
            cache.cache(categories, key: key)
            return categories
        } catch {
            if let cached: [BehaviorCategory] = cache.fetch([BehaviorCategory].self, key: key) {
                return cached
            }
            return BehaviorCategory.defaultPositiveCategories + BehaviorCategory.defaultNegativeCategories
        }
    }
    
    func createCategory(_ category: BehaviorCategory) async throws {
        try await supabaseService.createBehaviorCategory(category)
        cache.invalidate(key: "categories_\(category.classId)")
    }
    
    func updateCategory(_ category: BehaviorCategory) async throws {
        try await supabaseService.updateBehaviorCategory(category)
        cache.invalidate(key: "categories_\(category.classId)")
    }
    
    func deleteCategory(id: UUID) async throws {
        try await supabaseService.deleteBehaviorCategory(id: id)
        cache.invalidate(key: "categories_")
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
