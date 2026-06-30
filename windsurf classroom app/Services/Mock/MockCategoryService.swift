import Foundation

final class MockCategoryService: CategoryServiceProtocol {
    var fetchCategoriesResult: Result<[BehaviorCategory], Error>?
    var createCategoryError: Error?
    var updateCategoryError: Error?
    var deleteCategoryError: Error?

    func fetchCategories(classId: UUID) async throws -> [BehaviorCategory] {
        guard let result = fetchCategoriesResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let categories): return categories
        case .failure(let error): throw error
        }
    }

    func createCategory(_ category: BehaviorCategory) async throws {
        if let error = createCategoryError { throw error }
    }

    func updateCategory(_ category: BehaviorCategory) async throws {
        if let error = updateCategoryError { throw error }
    }

    func deleteCategory(id: UUID) async throws {
        if let error = deleteCategoryError { throw error }
    }

    static func configuredForTesting() -> MockCategoryService {
        let mock = MockCategoryService()
        mock.fetchCategoriesResult = .success(TestData.makeCategories())
        return mock
    }
}
