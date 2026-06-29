import Foundation

protocol CategoryServiceProtocol: AnyObject {
    func fetchCategories(classId: UUID) async throws -> [BehaviorCategory]
    func createCategory(_ category: BehaviorCategory) async throws
    func updateCategory(_ category: BehaviorCategory) async throws
    func deleteCategory(id: UUID) async throws
}
