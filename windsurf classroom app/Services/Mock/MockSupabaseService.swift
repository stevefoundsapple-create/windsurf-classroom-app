import Foundation
import Supabase

final class MockSupabaseService: SupabaseServiceProtocol {
    var fetchStudentsResult: Result<[Student], Error>?
    var fetchStudentResult: Result<Student, Error>?
    var fetchClassResult: Result<Class, Error>?
    var fetchClassByTeacherIdResult: Result<Class?, Error>?
    var fetchClassByCodeResult: Result<Class?, Error>?
    var fetchProfileResult: Result<UserProfile, Error>?
    var fetchStudentByParentIdResult: Result<Student?, Error>?
    var fetchStudentByUserIdResult: Result<Student?, Error>?
    var fetchBehaviorEventsResult: Result<[BehaviorEvent], Error>?
    var fetchBehaviorEventsForClassResult: Result<[BehaviorEvent], Error>?
    var fetchBehaviorCategoriesResult: Result<[BehaviorCategory], Error>?
    var fetchStudentsByParentIdResult: Result<[Student], Error>?
    var searchStudentsByNameResult: Result<[Student], Error>?
    var fetchNotificationPreferencesResult: Result<NotificationPreferences?, Error>?
    var signInResult: Result<Session, Error>?
    var getCurrentSessionUserIdResult: UUID?
    var getCurrentSessionResult: Result<Session?, Error>?

    lazy var realtime: RealtimeClientV2 = {
        RealtimeClientV2(
            url: URL(string: "https://example.com")!,
            options: RealtimeClientOptions()
        )
    }()

    func signIn(email: String, password: String) async throws -> Session {
        guard let result = signInResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let session): return session
        case .failure(let error): throw error
        }
    }

    func signOut() async throws {}

    func getCurrentSession() async throws -> Session? {
        guard let result = getCurrentSessionResult else { return nil }
        switch result {
        case .success(let session): return session
        case .failure(let error): throw error
        }
    }

    func getCurrentSessionUserId() async throws -> UUID? {
        return getCurrentSessionUserIdResult
    }

    func createClass(_ classObj: Class) async throws {}
    func createClassViaRPC(_ classObj: Class) async throws {}
    func fetchClass(id: UUID) async throws -> Class {
        guard let result = fetchClassResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let classObj): return classObj
        case .failure(let error): throw error
        }
    }

    func fetchClassByTeacherId(teacherId: UUID) async throws -> Class? {
        guard let result = fetchClassByTeacherIdResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let classObj): return classObj
        case .failure(let error): throw error
        }
    }

    func fetchClassByCode(_ code: String) async throws -> Class? {
        guard let result = fetchClassByCodeResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let classObj): return classObj
        case .failure(let error): throw error
        }
    }

    func updateProfileClassId(userId: UUID, classId: UUID) async throws {}

    func fetchProfile(userId: UUID) async throws -> UserProfile {
        guard let result = fetchProfileResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let profile): return profile
        case .failure(let error): throw error
        }
    }

    func createProfile(_ profile: UserProfile) async throws {}

    func fetchStudents(classId: UUID) async throws -> [Student] {
        guard let result = fetchStudentsResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let students): return students
        case .failure(let error): throw error
        }
    }

    func fetchStudent(id: UUID) async throws -> Student {
        guard let result = fetchStudentResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let student): return student
        case .failure(let error): throw error
        }
    }

    func fetchStudentByParentId(parentId: UUID) async throws -> Student? {
        guard let result = fetchStudentByParentIdResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let student): return student
        case .failure(let error): throw error
        }
    }

    func fetchStudentByUserId(userId: UUID) async throws -> Student? {
        guard let result = fetchStudentByUserIdResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let student): return student
        case .failure(let error): throw error
        }
    }

    func createStudent(_ student: Student) async throws {}
    func createStudentViaRPC(_ student: Student) async throws {}

    func updateStudentPoints(studentId: UUID, newTotal: Int) async throws {}

    func logBehaviorEvent(_ event: BehaviorEvent) async throws {}

    func fetchBehaviorEvents(studentId: UUID, limit: Int) async throws -> [BehaviorEvent] {
        guard let result = fetchBehaviorEventsResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let events): return events
        case .failure(let error): throw error
        }
    }

    func fetchBehaviorEventsForClass(classId: UUID, limit: Int) async throws -> [BehaviorEvent] {
        guard let result = fetchBehaviorEventsForClassResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let events): return events
        case .failure(let error): throw error
        }
    }

    func fetchBehaviorCategories(classId: UUID) async throws -> [BehaviorCategory] {
        guard let result = fetchBehaviorCategoriesResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let categories): return categories
        case .failure(let error): throw error
        }
    }

    func createBehaviorCategory(_ category: BehaviorCategory) async throws {}
    func updateBehaviorCategory(_ category: BehaviorCategory) async throws {}
    func deleteBehaviorCategory(id: UUID) async throws {}
    func saveDeviceToken(_ token: String, forUserId userId: UUID) async throws {}
    func deleteDeviceToken(_ token: String, forUserId userId: UUID) async throws {}

    func searchStudentsByName(_ name: String) async throws -> [Student] {
        guard let result = searchStudentsByNameResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let students): return students
        case .failure(let error): throw error
        }
    }

    func linkParentToStudent(parentId: UUID, studentId: UUID) async throws {}
    func unlinkParentFromStudent(studentId: UUID) async throws {}

    func fetchStudentsByParentId(parentId: UUID) async throws -> [Student] {
        guard let result = fetchStudentsByParentIdResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let students): return students
        case .failure(let error): throw error
        }
    }

    func fetchNotificationPreferences(userId: UUID) async throws -> NotificationPreferences? {
        guard let result = fetchNotificationPreferencesResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let prefs): return prefs
        case .failure(let error): throw error
        }
    }

    func createNotificationPreferences(_ preferences: NotificationPreferences) async throws {}
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws {}
    func triggerBehaviorNotification(eventId: UUID, studentId: UUID, category: String, isPositive: Bool, points: Int, note: String?) async throws {}
    func deleteAccount(userId: UUID) async throws {}

    static func configuredForTesting() -> MockSupabaseService {
        let mock = MockSupabaseService()
        let classId = UUID()
        let student = TestData.makeStudent(classId: classId)

        if UITestHarness.isErrorState {
            mock.fetchStudentsResult = .failure(NSError(domain: "mock", code: 500))
            mock.fetchStudentByParentIdResult = .failure(NSError(domain: "mock", code: 500))
            mock.fetchStudentByUserIdResult = .failure(NSError(domain: "mock", code: 500))
            mock.fetchBehaviorEventsResult = .failure(NSError(domain: "mock", code: 500))
            mock.fetchStudentsByParentIdResult = .failure(NSError(domain: "mock", code: 500))
        } else if UITestHarness.isEmptyState {
            mock.fetchStudentsResult = .success([])
            mock.fetchStudentByParentIdResult = .success(nil)
            mock.fetchStudentByUserIdResult = .success(TestData.makeStudentWithUserId(classId: classId))
            mock.fetchBehaviorEventsResult = .success([])
            mock.fetchStudentsByParentIdResult = .success([])
        } else {
            mock.fetchStudentsResult = .success(TestData.makeStudents())
            mock.fetchStudentResult = .success(student)
            mock.fetchClassResult = .success(TestData.makeClass(classId: classId))
            mock.fetchClassByTeacherIdResult = .success(TestData.makeClass(classId: classId))
            mock.fetchClassByCodeResult = .success(TestData.makeClass(classId: classId))
            mock.fetchStudentByParentIdResult = .success(student)
            mock.fetchStudentByUserIdResult = .success(TestData.makeStudentWithUserId(classId: classId))
            mock.fetchBehaviorEventsResult = .success(TestData.makeBehaviorEvents())
            mock.fetchBehaviorEventsForClassResult = .success(TestData.makeBehaviorEvents())
            mock.fetchBehaviorCategoriesResult = .success(TestData.makeCategories())
            mock.fetchProfileResult = .success(TestData.makeTeacherProfile())
            mock.fetchStudentsByParentIdResult = .success(TestData.makeStudents())
            mock.searchStudentsByNameResult = .success(TestData.makeStudents())
            mock.fetchNotificationPreferencesResult = .success(NotificationPreferences(userId: UUID()))
            let session = TestData.makeSession()
            mock.signInResult = .success(session)
            mock.getCurrentSessionResult = .success(session)
        }

        return mock
    }
}
