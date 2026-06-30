import Foundation

enum ServiceFactory {
    static func makeAuthService() -> AuthServiceProtocol {
        if UITestHarness.isUITesting {
            return MockAuthService.configuredForTesting()
        }
        return AuthService()
    }

    static func makeStudentService() -> StudentServiceProtocol {
        if UITestHarness.isUITesting {
            return MockStudentService.configuredForTesting()
        }
        return StudentService()
    }

    static func makeBehaviorService() -> BehaviorServiceProtocol {
        if UITestHarness.isUITesting {
            return MockBehaviorService.configuredForTesting()
        }
        return BehaviorService()
    }

    static func makeCategoryService() -> CategoryServiceProtocol {
        if UITestHarness.isUITesting {
            return MockCategoryService.configuredForTesting()
        }
        return CategoryService()
    }

    static func makeSupabaseService() -> SupabaseServiceProtocol {
        if UITestHarness.isUITesting {
            return MockSupabaseService.configuredForTesting()
        }
        return CachedSupabaseService.shared
    }
}
