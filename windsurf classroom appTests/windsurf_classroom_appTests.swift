import Testing
@testable import windsurf_classroom_app
import Foundation
import Supabase

// MARK: - Mock AuthService

final class MockAuthService: AuthServiceProtocol {
    var signInResult: Result<Session, Error>?
    var signOutError: Error?
    var signOutCalled = false
    var fetchProfileResult: Result<UserProfile, Error>?
    var currentSessionResult: Result<Session?, Error>?
    var currentUserResult: Result<User?, Error>?

    func signIn(email: String, password: String) async throws -> Session {
        guard let result = signInResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let session): return session
        case .failure(let error): throw error
        }
    }

    func signOut() async throws {
        signOutCalled = true
        if let error = signOutError { throw error }
    }

    func fetchProfile(userId: UUID) async throws -> UserProfile {
        guard let result = fetchProfileResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let profile): return profile
        case .failure(let error): throw error
        }
    }

    func currentSession() async throws -> Session? {
        guard let result = currentSessionResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let session): return session
        case .failure(let error): throw error
        }
    }

    func currentUser() async throws -> User? {
        guard let result = currentUserResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let user): return user
        case .failure(let error): throw error
        }
    }
}

// MARK: - Mock BehaviorService

final class MockBehaviorService: BehaviorServiceProtocol {
    var logEventError: Error?
    var logEventCall: (studentId: UUID, teacherId: UUID, label: String, points: Int)?
    var fetchEventsResult: Result<[BehaviorEvent], Error>?
    var fetchEventsForClassResult: Result<[BehaviorEvent], Error>?

    func logEvent(studentId: UUID, teacherId: UUID, category: String, isPositive: Bool, points: Int, note: String?) async throws {
        logEventCall = (studentId, teacherId, category, points)
        if let error = logEventError { throw error }
    }

    func fetchEvents(for studentId: UUID, limit: Int) async throws -> [BehaviorEvent] {
        guard let result = fetchEventsResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let events): return events
        case .failure(let error): throw error
        }
    }

    func fetchEventsForClass(classId: UUID, limit: Int) async throws -> [BehaviorEvent] {
        guard let result = fetchEventsForClassResult else { throw MockError.unexpectedCall }
        switch result {
        case .success(let events): return events
        case .failure(let error): throw error
        }
    }
}

// MARK: - Mock CategoryService

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
}

// MARK: - Mock StudentService

final class MockStudentService: StudentServiceProtocol {
    var fetchStudentsResult: Result<[Student], Error>?
    var fetchStudentResult: Result<Student, Error>?
    var createStudentError: Error?
    var updateStudentPointsError: Error?
    var createdStudent: Student?
    var updatedStudentId: UUID?
    var updatedTotal: Int?

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

    func createStudent(_ student: Student) async throws {
        createdStudent = student
        if let error = createStudentError { throw error }
    }

    func updateStudentPoints(studentId: UUID, newTotal: Int) async throws {
        updatedStudentId = studentId
        updatedTotal = newTotal
        if let error = updateStudentPointsError { throw error }
    }
}

// MARK: - Mock SupabaseService

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
}

// MARK: - Test Error

enum MockError: Error {
    case unexpectedCall
}

// MARK: - Test Helpers

func makeSession(userId: UUID = UUID()) -> Session {
    Session(
        providerToken: nil,
        providerRefreshToken: nil,
        accessToken: "mock_access_token",
        tokenType: "bearer",
        expiresIn: 3600,
        expiresAt: Date().timeIntervalSince1970 + 3600,
        refreshToken: "mock_refresh_token",
        weakPassword: nil,
        user: User(
            id: userId,
            appMetadata: [:],
            userMetadata: [:],
            aud: "authenticated",
            confirmationSentAt: nil,
            recoverySentAt: nil,
            emailChangeSentAt: nil,
            newEmail: nil,
            invitedAt: nil,
            actionLink: nil,
            email: "test@example.com",
            phone: nil,
            createdAt: Date(),
            confirmedAt: Date(),
            emailConfirmedAt: Date(),
            phoneConfirmedAt: nil,
            lastSignInAt: Date(),
            role: nil,
            updatedAt: Date(),
            identities: nil,
            isAnonymous: false,
            factors: nil
        )
    )
}

func makeTeacherProfile(userId: UUID = UUID()) -> UserProfile {
    UserProfile(id: userId, name: "Test Teacher", email: "teacher@example.com", role: .teacher, classId: nil)
}

func makeStudent(id: UUID = UUID(), userId: UUID? = nil, name: String = "Test Student", classId: UUID = UUID(), pointTotal: Int = 10) -> Student {
    Student(id: id, userId: userId, name: name, classId: classId, parentId: nil, pointTotal: pointTotal)
}

func makeBehaviorEvent(studentId: UUID = UUID(), points: Int = 5, isPositive: Bool = true, createdAt: Date = Date()) -> BehaviorEvent {
    BehaviorEvent(
        id: UUID(),
        studentId: studentId,
        teacherId: UUID(),
        category: "Participated",
        isPositive: isPositive,
        points: points,
        note: nil,
        createdAt: createdAt
    )
}

func makeCategory(id: UUID = UUID(), label: String = "Participated", isPositive: Bool = true, points: Int = 2) -> BehaviorCategory {
    BehaviorCategory(id: id, classId: UUID(), label: label, isPositive: isPositive, points: points)
}

// MARK: - AuthViewModel Tests

@Suite("AuthViewModel")
@MainActor
struct AuthViewModelTests {

    @Test("Login succeeds and sets currentUser")
    func loginSuccess() async throws {
        let mockAuth = MockAuthService()
        let userId = UUID()
        let session = makeSession(userId: userId)
        let profile = makeTeacherProfile(userId: userId)
        mockAuth.signInResult = .success(session)
        mockAuth.fetchProfileResult = .success(profile)
        mockAuth.currentSessionResult = .success(nil)

        let sut = AuthViewModel(authService: mockAuth)

        #expect(sut.currentUser == nil)
        #expect(sut.isLoading == false)

        await sut.login(email: "teacher@example.com", password: "password")

        #expect(sut.currentUser?.id == userId)
        #expect(sut.currentUser?.role == .teacher)
        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
    }

    @Test("Login failure sets errorMessage")
    func loginFailure() async throws {
        let mockAuth = MockAuthService()
        mockAuth.signInResult = .failure(NSError(domain: "test", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"]))
        mockAuth.currentSessionResult = .success(nil)

        let sut = AuthViewModel(authService: mockAuth)

        await sut.login(email: "bad@example.com", password: "wrong")

        #expect(sut.currentUser == nil)
        #expect(sut.errorMessage != nil)
        #expect(sut.isLoading == false)
    }

    @Test("Logout clears currentUser and calls signOut")
    func logoutClearsUser() async throws {
        let mockAuth = MockAuthService()
        let userId = UUID()
        let session = makeSession(userId: userId)
        let profile = makeTeacherProfile(userId: userId)
        mockAuth.signInResult = .success(session)
        mockAuth.fetchProfileResult = .success(profile)
        mockAuth.currentSessionResult = .success(nil)

        let sut = AuthViewModel(authService: mockAuth)
        await sut.login(email: "teacher@example.com", password: "password")
        #expect(sut.currentUser != nil)

        await sut.logout()

        #expect(sut.currentUser == nil)
        #expect(mockAuth.signOutCalled)
    }

    @Test("Existing session restores currentUser on init")
    func existingSessionRestoresUser() async throws {
        let mockAuth = MockAuthService()
        let userId = UUID()
        let session = makeSession(userId: userId)
        let profile = makeTeacherProfile(userId: userId)
        mockAuth.currentSessionResult = .success(session)
        mockAuth.fetchProfileResult = .success(profile)

        let sut = AuthViewModel(authService: mockAuth)

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentUser?.id == userId)
    }
}

// MARK: - LogBehaviorViewModel Tests

@Suite("LogBehaviorViewModel")
@MainActor
struct LogBehaviorViewModelTests {

    @Test("Loads categories filtered by isPositive")
    func loadCategories() async throws {
        let mockBehavior = MockBehaviorService()
        let mockCategory = MockCategoryService()
        let classId = UUID()
        let positiveCategories = [
            makeCategory(label: "Participated", isPositive: true),
            makeCategory(label: "Helped Others", isPositive: true)
        ]
        mockCategory.fetchCategoriesResult = .success(positiveCategories)

        let sut = LogBehaviorViewModel(
            teacherId: UUID(),
            classId: classId,
            behaviorService: mockBehavior,
            categoryService: mockCategory
        )

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.categories.count == 2)
        #expect(sut.categories.allSatisfy { $0.isPositive })
        #expect(sut.isPositive == true)
    }

    @Test("Toggling behavior type reloads categories")
    func toggleBehaviorType() async throws {
        let mockBehavior = MockBehaviorService()
        let mockCategory = MockCategoryService()
        let classId = UUID()
        let positiveCategories = [makeCategory(label: "Participated", isPositive: true)]
        let negativeCategories = [makeCategory(label: "Off-task", isPositive: false)]

        mockCategory.fetchCategoriesResult = .success(positiveCategories)

        let sut = LogBehaviorViewModel(
            teacherId: UUID(),
            classId: classId,
            behaviorService: mockBehavior,
            categoryService: mockCategory
        )

        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(sut.isPositive == true)

        mockCategory.fetchCategoriesResult = .success(negativeCategories)
        sut.toggleBehaviorType()

        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(sut.isPositive == false)
        #expect(sut.selectedCategory == nil)
        #expect(sut.categories.allSatisfy { !$0.isPositive })
    }

    @Test("Logging behavior calls optimistic update")
    func logBehaviorCallsOptimisticUpdate() async throws {
        let mockBehavior = MockBehaviorService()
        let mockCategory = MockCategoryService()
        let classId = UUID()
        let student = makeStudent(classId: classId, pointTotal: 10)
        let category = makeCategory(label: "Participated", isPositive: true, points: 5)

        mockCategory.fetchCategoriesResult = .success([category])
        mockBehavior.logEventError = nil

        let sut = LogBehaviorViewModel(
            teacherId: UUID(),
            classId: classId,
            behaviorService: mockBehavior,
            categoryService: mockCategory
        )

        try? await Task.sleep(nanoseconds: 50_000_000)

        sut.selectCategory(category)

        var updatedPointTotal = 0
        sut.onOptimisticUpdate = { _, newTotal in
            updatedPointTotal = newTotal
        }

        await sut.logEvent(for: student)

        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(updatedPointTotal == 15)
        #expect(mockBehavior.logEventCall?.points == 5)
        #expect(mockBehavior.logEventCall?.label == "Participated")
        #expect(sut.isSubmitting == false)
    }

    @Test("Logging behavior rollbacks optimistic update on failure")
    func logBehaviorRollsBackOnError() async throws {
        let mockBehavior = MockBehaviorService()
        let mockCategory = MockCategoryService()
        let classId = UUID()
        let student = makeStudent(classId: classId, pointTotal: 10)
        let category = makeCategory(label: "Participated", isPositive: true, points: 5)

        mockCategory.fetchCategoriesResult = .success([category])
        mockBehavior.logEventError = NSError(domain: "test", code: -1, userInfo: nil)

        let sut = LogBehaviorViewModel(
            teacherId: UUID(),
            classId: classId,
            behaviorService: mockBehavior,
            categoryService: mockCategory
        )

        try? await Task.sleep(nanoseconds: 50_000_000)

        sut.selectCategory(category)

        var updatedPointTotal = 0
        sut.onOptimisticUpdate = { _, newTotal in
            updatedPointTotal = newTotal
        }

        await sut.logEvent(for: student)

        #expect(updatedPointTotal == 10)
        #expect(sut.errorMessage != nil)
        #expect(sut.isSubmitting == false)
    }
}

// MARK: - AddStudentViewModel Tests

@Suite("AddStudentViewModel")
@MainActor
struct AddStudentViewModelTests {

    @Test("Adds student successfully")
    func addStudentSuccess() async throws {
        let mockStudent = MockStudentService()
        let classId = UUID()
        let sut = AddStudentViewModel(classId: classId, studentService: mockStudent)
        sut.studentName = "Alice"

        let result = await sut.addStudent()

        #expect(result == true)
        #expect(mockStudent.createdStudent != nil)
        #expect(mockStudent.createdStudent?.name == "Alice")
        #expect(mockStudent.createdStudent?.classId == classId)
        #expect(mockStudent.createdStudent?.pointTotal == 0)
        #expect(sut.studentName.isEmpty)
    }

    @Test("Returns false for empty name")
    func addStudentEmptyName() async throws {
        let mockStudent = MockStudentService()
        let sut = AddStudentViewModel(classId: UUID(), studentService: mockStudent)

        sut.studentName = "   "
        let result = await sut.addStudent()

        #expect(result == false)
        #expect(mockStudent.createdStudent == nil)
    }

    @Test("Sets errorMessage on create failure")
    func addStudentFailure() async throws {
        let mockStudent = MockStudentService()
        mockStudent.createStudentError = NSError(domain: "test", code: -1)
        let sut = AddStudentViewModel(classId: UUID(), studentService: mockStudent)
        sut.studentName = "Bob"

        let result = await sut.addStudent()

        #expect(result == false)
        #expect(sut.errorMessage != nil)
    }

    @Test("canSubmit reflects validation state")
    func canSubmitValidation() {
        let sut = AddStudentViewModel(classId: UUID())

        #expect(sut.canSubmit == false)

        sut.studentName = "Charlie"
        #expect(sut.canSubmit == true)

        sut.isLoading = true
        #expect(sut.canSubmit == false)
    }
}

// MARK: - StudentProfileViewModel Tests

@Suite("StudentProfileViewModel")
@MainActor
struct StudentProfileViewModelTests {

    @Test("Loads events for student")
    func loadEvents() async throws {
        let mockBehavior = MockBehaviorService()
        let studentId = UUID()
        let student = makeStudent(id: studentId)
        let events = [
            makeBehaviorEvent(studentId: studentId, points: 5, createdAt: Date()),
            makeBehaviorEvent(studentId: studentId, points: -2, isPositive: false, createdAt: Date())
        ]
        mockBehavior.fetchEventsResult = .success(events)

        let sut = StudentProfileViewModel(student: student, behaviorService: mockBehavior)

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.events.count == 2)
        #expect(sut.totalPositiveEvents == 1)
        #expect(sut.totalNegativeEvents == 1)
        #expect(sut.netPointsThisPeriod == 3)
    }

    @Test("Filtering by today returns only today events")
    func filterToday() async throws {
        let mockBehavior = MockBehaviorService()
        let studentId = UUID()
        let student = makeStudent(id: studentId)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let events = [
            makeBehaviorEvent(studentId: studentId, createdAt: Date()),
            makeBehaviorEvent(studentId: studentId, createdAt: yesterday)
        ]
        mockBehavior.fetchEventsResult = .success(events)

        let sut = StudentProfileViewModel(student: student, behaviorService: mockBehavior)
        sut.filter = .today

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.events.count == 1)
    }

    @Test("Sets errorMessage on fetch failure")
    func fetchFailure() async throws {
        let mockBehavior = MockBehaviorService()
        mockBehavior.fetchEventsResult = .failure(NSError(domain: "test", code: -1))

        let sut = StudentProfileViewModel(student: makeStudent(), behaviorService: mockBehavior)

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.events.isEmpty)
        #expect(sut.errorMessage != nil)
    }

    @Test("Computed properties reflect correct state")
    func computedProperties() async throws {
        let mockBehavior = MockBehaviorService()
        let studentId = UUID()
        let student = makeStudent(id: studentId, pointTotal: 10)
        let today = Date()
        let events = [
            makeBehaviorEvent(studentId: studentId, points: 5, isPositive: true, createdAt: today),
            makeBehaviorEvent(studentId: studentId, points: 3, isPositive: true, createdAt: today),
            makeBehaviorEvent(studentId: studentId, points: -2, isPositive: false, createdAt: today)
        ]
        mockBehavior.fetchEventsResult = .success(events)

        let sut = StudentProfileViewModel(student: student, behaviorService: mockBehavior)

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.studentName == "Test Student")
        #expect(sut.studentPointTotal == 10)
        #expect(sut.totalPositiveEvents == 2)
        #expect(sut.totalNegativeEvents == 1)
        #expect(sut.netPointsThisPeriod == 6)
    }
}

// MARK: - ClassDashboardViewModel Tests

@Suite("ClassDashboardViewModel")
@MainActor
struct ClassDashboardViewModelTests {

    @Test("Fetches students on init with classId")
    func fetchStudents() async throws {
        let mockStudent = MockStudentService()
        let mockSupabase = MockSupabaseService()
        let classId = UUID()
        let students = [
            makeStudent(id: UUID(), name: "Alice", classId: classId),
            makeStudent(id: UUID(), name: "Bob", classId: classId)
        ]
        mockStudent.fetchStudentsResult = .success(students)
        mockSupabase.fetchClassResult = .success(Class(id: classId, teacherId: UUID(), name: "Test Class", classCode: "ABC123"))

        let sut = ClassDashboardViewModel(classId: classId, studentService: mockStudent, supabaseService: mockSupabase)

        try? await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.students.count == 2)
        #expect(sut.students[0].name == "Alice")
        #expect(sut.students[1].name == "Bob")
        #expect(sut.isLoading == false)
    }

    @Test("Shows error message when fetch fails")
    func fetchFailure() async throws {
        let mockStudent = MockStudentService()
        let mockSupabase = MockSupabaseService()
        mockStudent.fetchStudentsResult = .failure(NSError(domain: "test", code: -1))
        mockSupabase.fetchClassResult = .success(Class(id: UUID(), teacherId: UUID(), name: "Test Class", classCode: "ABC123"))

        let sut = ClassDashboardViewModel(classId: UUID(), studentService: mockStudent, supabaseService: mockSupabase)

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.students.isEmpty)
        #expect(sut.errorMessage != nil)
        #expect(sut.isLoading == false)
    }

    @Test("Selects a student")
    func selectStudent() {
        let mockStudent = MockStudentService()
        let mockSupabase = MockSupabaseService()
        let student = makeStudent()

        let sut = ClassDashboardViewModel(classId: UUID(), studentService: mockStudent, supabaseService: mockSupabase)
        sut.selectStudent(student)

        #expect(sut.selectedStudent?.id == student.id)
    }

    @Test("Does not fetch when classId is nil")
    func noFetchWithoutClassId() {
        let mockStudent = MockStudentService()
        let mockSupabase = MockSupabaseService()

        let sut = ClassDashboardViewModel(classId: nil, studentService: mockStudent, supabaseService: mockSupabase)

        #expect(sut.students.isEmpty)
        #expect(sut.isLoading == false)
        #expect(sut.classCode == nil)
    }
}

// MARK: - ParentFeedViewModel Tests

@Suite("ParentFeedViewModel")
@MainActor
struct ParentFeedViewModelTests {

    @Test("Fetches child and events")
    func fetchChildAndEvents() async throws {
        let mockSupabase = MockSupabaseService()
        let parentId = UUID()
        let child = makeStudent(name: "Child", pointTotal: 20)
        let events = [
            makeBehaviorEvent(studentId: child.id, points: 5),
            makeBehaviorEvent(studentId: child.id, points: -3, isPositive: false)
        ]
        mockSupabase.fetchStudentByParentIdResult = .success(child)
        mockSupabase.fetchBehaviorEventsResult = .success(events)

        let sut = ParentFeedViewModel(supabaseService: mockSupabase)

        await sut.fetchChildAndEvents(parentId: parentId)

        #expect(sut.child?.name == "Child")
        #expect(sut.events.count == 2)
        #expect(sut.isLoading == false)
    }

    @Test("Handles no child found")
    func noChildFound() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.fetchStudentByParentIdResult = .success(nil)

        let sut = ParentFeedViewModel(supabaseService: mockSupabase)

        await sut.fetchChildAndEvents(parentId: UUID())

        #expect(sut.child == nil)
        #expect(sut.isLoading == false)
    }

    @Test("todayPointTotal calculates correctly")
    func todayPointTotal() async throws {
        let mockSupabase = MockSupabaseService()
        let child = makeStudent()
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let events = [
            makeBehaviorEvent(studentId: child.id, points: 5, createdAt: today),
            makeBehaviorEvent(studentId: child.id, points: 3, createdAt: today),
            makeBehaviorEvent(studentId: child.id, points: -2, isPositive: false, createdAt: yesterday)
        ]
        mockSupabase.fetchStudentByParentIdResult = .success(child)
        mockSupabase.fetchBehaviorEventsResult = .success(events)

        let sut = ParentFeedViewModel(supabaseService: mockSupabase)
        await sut.fetchChildAndEvents(parentId: UUID())

        #expect(sut.todayPointTotal == 8)
    }
}

// MARK: - ClassSetupViewModel Tests

@Suite("ClassSetupViewModel")
@MainActor
struct ClassSetupViewModelTests {

    @Test("Creates class successfully")
    func createClassSuccess() async throws {
        let mockSupabase = MockSupabaseService()
        let sut = ClassSetupViewModel(supabaseService: mockSupabase)
        sut.className = "Test Class"
        sut.setTeacherId(UUID())

        let result = await sut.createClass()

        #expect(result != nil)
        #expect(sut.generatedClassCode != nil)
        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
    }

    @Test("Fails with empty class name")
    func errorForEmptyClassName() async throws {
        let mockSupabase = MockSupabaseService()
        let sut = ClassSetupViewModel(supabaseService: mockSupabase)
        sut.className = ""
        sut.setTeacherId(UUID())

        let result = await sut.createClass()

        #expect(result == nil)
        #expect(sut.errorMessage == "Please enter a class name")
    }

    @Test("canSubmit reflects validation")
    func canSubmitValidation() {
        let sut = ClassSetupViewModel()

        #expect(sut.canSubmit == false)

        sut.className = "Math Class"
        sut.isLoading = false
        #expect(sut.canSubmit == true)

        sut.isLoading = true
        #expect(sut.canSubmit == false)
    }
}

// MARK: - StudentHomeViewModel Tests

@Suite("StudentHomeViewModel")
@MainActor
struct StudentHomeViewModelTests {

    @Test("Fetch events succeeds with student found")
    func fetchEventsSuccess() async throws {
        let mockSupabase = MockSupabaseService()
        let userId = UUID()
        let student = makeStudent(userId: userId, name: "Test Student", pointTotal: 15)
        let events = [
            makeBehaviorEvent(studentId: student.id, points: 5),
            makeBehaviorEvent(studentId: student.id, points: -2, isPositive: false)
        ]
        mockSupabase.fetchStudentByUserIdResult = .success(student)
        mockSupabase.fetchBehaviorEventsResult = .success(events)

        let sut = StudentHomeViewModel(supabaseService: mockSupabase)
        await sut.fetchEvents(userId: userId)

        #expect(sut.needsSetup == false)
        #expect(sut.pointTotal == 15)
        #expect(sut.events.count == 2)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test("Fetch events sets needsSetup when no student found")
    func fetchEventsNoStudent() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.fetchStudentByUserIdResult = .success(nil)

        let sut = StudentHomeViewModel(supabaseService: mockSupabase)
        await sut.fetchEvents(userId: UUID())

        #expect(sut.needsSetup == true)
        #expect(sut.events.isEmpty)
        #expect(sut.isLoading == false)
    }

    @Test("Fetch events sets errorMessage on failure")
    func fetchEventsFailure() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.fetchStudentByUserIdResult = .failure(NSError(domain: "test", code: -1))

        let sut = StudentHomeViewModel(supabaseService: mockSupabase)
        await sut.fetchEvents(userId: UUID())

        #expect(sut.errorMessage != nil)
        #expect(sut.isLoading == false)
    }

    @Test("Refresh events resets needsSetup")
    func refreshEvents() async throws {
        let mockSupabase = MockSupabaseService()
        let student = makeStudent()
        mockSupabase.fetchStudentByUserIdResult = .success(student)
        mockSupabase.fetchBehaviorEventsResult = .success([])

        let sut = StudentHomeViewModel(supabaseService: mockSupabase)
        await sut.fetchEvents(userId: UUID())
        sut.needsSetup = true

        await sut.refreshEvents(userId: UUID())

        #expect(sut.needsSetup == false)
    }

    @Test("Setup complete resets needsSetup and fetches events")
    func setupComplete() async throws {
        let mockSupabase = MockSupabaseService()
        let student = makeStudent()
        mockSupabase.fetchStudentByUserIdResult = .success(student)
        mockSupabase.fetchBehaviorEventsResult = .success([])

        let sut = StudentHomeViewModel(supabaseService: mockSupabase)
        sut.needsSetup = true

        sut.setupComplete(userId: UUID())

        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(sut.needsSetup == false)
    }
}

// MARK: - LinkChildViewModel Tests

@Suite("LinkChildViewModel")
@MainActor
struct LinkChildViewModelTests {

    @Test("Search with empty name sets error")
    func searchEmptyName() async {
        let mockSupabase = MockSupabaseService()
        let sut = LinkChildViewModel(supabaseService: mockSupabase)
        sut.studentName = ""

        await sut.searchStudents()

        #expect(sut.errorMessage == "Please enter your child's name")
        #expect(sut.isSearching == false)
    }

    @Test("Search with results populates list")
    func searchWithResults() async throws {
        let mockSupabase = MockSupabaseService()
        let students = [makeStudent(name: "Alice"), makeStudent(name: "Bob")]
        mockSupabase.searchStudentsByNameResult = .success(students)

        let sut = LinkChildViewModel(supabaseService: mockSupabase)
        sut.studentName = "Ali"

        await sut.searchStudents()

        #expect(sut.searchResults.count == 2)
        #expect(sut.errorMessage == nil)
        #expect(sut.isSearching == false)
    }

    @Test("Search with no results sets error")
    func searchNoResults() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.searchStudentsByNameResult = .success([])

        let sut = LinkChildViewModel(supabaseService: mockSupabase)
        sut.studentName = "Xyz"

        await sut.searchStudents()

        #expect(sut.searchResults.isEmpty)
        #expect(sut.errorMessage == "No students found with that name. Please check the spelling or contact your child's teacher.")
    }

    @Test("Search with error sets errorMessage")
    func searchError() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.searchStudentsByNameResult = .failure(NSError(domain: "test", code: -1))

        let sut = LinkChildViewModel(supabaseService: mockSupabase)
        sut.studentName = "Alice"

        await sut.searchStudents()

        #expect(sut.errorMessage == "Unable to search. Please check your connection and try again.")
    }

    @Test("Select student sets selectedStudent and shows confirmation")
    func selectStudent() {
        let sut = LinkChildViewModel()
        let student = makeStudent(name: "Alice")

        sut.selectStudent(student)

        #expect(sut.selectedStudent?.name == "Alice")
        #expect(sut.showConfirmation == true)
    }

    @Test("Link parent succeeds")
    func linkParentSuccess() async throws {
        let mockSupabase = MockSupabaseService()
        let parentId = UUID()
        let student = makeStudent(name: "Alice")

        let sut = LinkChildViewModel(supabaseService: mockSupabase)
        sut.selectStudent(student)

        let result = await sut.linkParentToStudent(parentId: parentId)

        #expect(result == true)
        #expect(sut.successMessage == "Successfully linked to Alice!")
        #expect(sut.errorMessage == nil)
        #expect(sut.isLinking == false)
    }

    @Test("Link parent with no selection returns false")
    func linkParentNoSelection() async {
        let sut = LinkChildViewModel()

        let result = await sut.linkParentToStudent(parentId: UUID())

        #expect(result == false)
        #expect(sut.errorMessage == "No student selected")
    }

    @Test("Link parent with search error returns gracefully")
    func linkParentSearchError() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.searchStudentsByNameResult = .failure(NSError(domain: "test", code: -1))

        let sut = LinkChildViewModel(supabaseService: mockSupabase)
        sut.studentName = "Alice"

        await sut.searchStudents()

        #expect(sut.errorMessage == "Unable to search. Please check your connection and try again.")
        #expect(sut.isSearching == false)
    }

    @Test("Reset clears all state")
    func resetState() {
        let sut = LinkChildViewModel()
        sut.studentName = "Alice"
        sut.searchResults = [makeStudent()]
        sut.errorMessage = "Some error"
        sut.successMessage = "Some success"
        sut.selectedStudent = makeStudent()
        sut.showConfirmation = true

        sut.reset()

        #expect(sut.studentName.isEmpty)
        #expect(sut.searchResults.isEmpty)
        #expect(sut.errorMessage == nil)
        #expect(sut.successMessage == nil)
        #expect(sut.selectedStudent == nil)
        #expect(sut.showConfirmation == false)
    }
}

// MARK: - ParentReportsViewModel Tests

@Suite("ParentReportsViewModel")
@MainActor
struct ParentReportsViewModelTests {

    @Test("Fetch reports succeeds with child and events")
    func fetchReportsSuccess() async throws {
        let mockSupabase = MockSupabaseService()
        let parentId = UUID()
        let child = makeStudent(name: "Test Child", pointTotal: 30)
        let today = Date()
        let thisWeek = Calendar.current.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let events = [
            makeBehaviorEvent(studentId: child.id, points: 5, createdAt: thisWeek),
            makeBehaviorEvent(studentId: child.id, points: -2, isPositive: false, createdAt: thisWeek)
        ]
        mockSupabase.fetchStudentByParentIdResult = .success(child)
        mockSupabase.fetchBehaviorEventsResult = .success(events)

        let sut = ParentReportsViewModel(supabaseService: mockSupabase)
        await sut.fetchReports(parentId: parentId)

        #expect(sut.child?.name == "Test Child")
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test("Fetch reports handles no child")
    func fetchReportsNoChild() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.fetchStudentByParentIdResult = .success(nil)

        let sut = ParentReportsViewModel(supabaseService: mockSupabase)
        await sut.fetchReports(parentId: UUID())

        #expect(sut.child == nil)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test("Fetch reports sets error on failure")
    func fetchReportsFailure() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.fetchStudentByParentIdResult = .failure(NSError(domain: "test", code: -1))

        let sut = ParentReportsViewModel(supabaseService: mockSupabase)
        await sut.fetchReports(parentId: UUID())

        #expect(sut.errorMessage != nil)
        #expect(sut.isLoading == false)
    }

    @Test("Calculates weekly statistics correctly")
    func weeklyStats() async throws {
        let mockSupabase = MockSupabaseService()
        let parentId = UUID()
        let child = makeStudent()
        let today = Date()
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
        let events = [
            makeBehaviorEvent(studentId: child.id, points: 5, createdAt: weekStart),
            makeBehaviorEvent(studentId: child.id, points: 3, createdAt: Calendar.current.date(byAdding: .day, value: 1, to: weekStart)!),
            makeBehaviorEvent(studentId: child.id, points: -2, isPositive: false, createdAt: weekStart),
            makeBehaviorEvent(studentId: child.id, points: 4, createdAt: lastWeek)
        ]
        mockSupabase.fetchStudentByParentIdResult = .success(child)
        mockSupabase.fetchBehaviorEventsResult = .success(events)

        let sut = ParentReportsViewModel(supabaseService: mockSupabase)
        await sut.fetchReports(parentId: parentId)

        #expect(sut.weeklyPointTotal == 6)
        #expect(sut.weeklyPositiveEvents == 2)
        #expect(sut.weeklyNegativeEvents == 1)
        #expect(sut.weeklyTrend.count == 7)
    }

    @Test("Generates previous weeks summaries")
    func previousWeeksSummaries() async throws {
        let mockSupabase = MockSupabaseService()
        let parentId = UUID()
        let child = makeStudent()
        let today = Date()
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let lastWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
        let lastWeekEvent = makeBehaviorEvent(studentId: child.id, points: 10, createdAt: lastWeekStart)
        let thisWeekEvent = makeBehaviorEvent(studentId: child.id, points: 5, createdAt: weekStart)
        mockSupabase.fetchStudentByParentIdResult = .success(child)
        mockSupabase.fetchBehaviorEventsResult = .success([lastWeekEvent, thisWeekEvent])

        let sut = ParentReportsViewModel(supabaseService: mockSupabase)
        await sut.fetchReports(parentId: parentId)

        #expect(sut.previousWeeks.count == 4)
        #expect(sut.weeklyPointTotal == 5)
    }
}

// MARK: - ParentSettingsViewModel Tests

@Suite("ParentSettingsViewModel")
@MainActor
struct ParentSettingsViewModelTests {

    @Test("Fetch children succeeds")
    func fetchChildrenSuccess() async throws {
        let mockSupabase = MockSupabaseService()
        let parentId = UUID()
        let children = [
            makeStudent(name: "Alice"),
            makeStudent(name: "Bob")
        ]
        mockSupabase.fetchStudentsByParentIdResult = .success(children)

        let sut = ParentSettingsViewModel(supabaseService: mockSupabase)
        await sut.fetchChildren(parentId: parentId)

        #expect(sut.children.count == 2)
        #expect(sut.children[0].name == "Alice")
        #expect(sut.isLoading == false)
    }

    @Test("Fetch children handles empty list")
    func fetchChildrenEmpty() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.fetchStudentsByParentIdResult = .success([])

        let sut = ParentSettingsViewModel(supabaseService: mockSupabase)
        await sut.fetchChildren(parentId: UUID())

        #expect(sut.children.isEmpty)
        #expect(sut.isLoading == false)
    }

    @Test("Fetch children sets error on failure")
    func fetchChildrenFailure() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.fetchStudentsByParentIdResult = .failure(NSError(domain: "test", code: -1))

        let sut = ParentSettingsViewModel(supabaseService: mockSupabase)
        await sut.fetchChildren(parentId: UUID())

        #expect(sut.errorMessage != nil)
        #expect(sut.isLoading == false)
    }

    @Test("Fetch notification preferences succeeds when they exist")
    func fetchPrefsExisting() async throws {
        let mockSupabase = MockSupabaseService()
        let userId = UUID()
        let prefs = NotificationPreferences(userId: userId)
        mockSupabase.fetchNotificationPreferencesResult = .success(prefs)

        let sut = ParentSettingsViewModel(supabaseService: mockSupabase)
        await sut.fetchNotificationPreferences(userId: userId)

        #expect(sut.notificationPreferences != nil)
        #expect(sut.notificationPreferences?.userId == userId)
        #expect(sut.isLoading == false)
    }

    @Test("Fetch notification preferences creates defaults when nil")
    func fetchPrefsCreatesDefaults() async throws {
        let mockSupabase = MockSupabaseService()
        let userId = UUID()
        mockSupabase.fetchNotificationPreferencesResult = .success(nil)

        let sut = ParentSettingsViewModel(supabaseService: mockSupabase)
        await sut.fetchNotificationPreferences(userId: userId)

        #expect(sut.notificationPreferences != nil)
        #expect(sut.notificationPreferences?.positiveBehaviors == true)
        #expect(sut.isLoading == false)
    }

    @Test("Fetch notification preferences sets error on failure")
    func fetchPrefsFailure() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.fetchNotificationPreferencesResult = .failure(NSError(domain: "test", code: -1))

        let sut = ParentSettingsViewModel(supabaseService: mockSupabase)
        await sut.fetchNotificationPreferences(userId: UUID())

        #expect(sut.errorMessage != nil)
        #expect(sut.isLoading == false)
    }

    @Test("Unlink child removes from list")
    func unlinkChildSuccess() async throws {
        let mockSupabase = MockSupabaseService()
        let child = makeStudent(name: "Alice")
        let sut = ParentSettingsViewModel(supabaseService: mockSupabase)
        sut.children = [child, makeStudent(name: "Bob")]

        await sut.unlinkChild(child)

        #expect(sut.children.count == 1)
        #expect(sut.children[0].name == "Bob")
        #expect(sut.isLoading == false)
    }

    @Test("Unlink child with no children does not crash")
    func unlinkChildEmptyList() async throws {
        let mockSupabase = MockSupabaseService()
        let sut = ParentSettingsViewModel(supabaseService: mockSupabase)

        await sut.unlinkChild(makeStudent(name: "Alice"))

        #expect(sut.children.isEmpty)
        #expect(sut.isLoading == false)
    }

    @Test("Update preference modifies value and saves")
    func updatePreference() async throws {
        let mockSupabase = MockSupabaseService()
        let userId = UUID()
        let prefs = NotificationPreferences(userId: userId)
        mockSupabase.fetchNotificationPreferencesResult = .success(prefs)

        let sut = ParentSettingsViewModel(supabaseService: mockSupabase)
        await sut.fetchNotificationPreferences(userId: userId)

        #expect(sut.notificationPreferences?.positiveBehaviors == true)

        await sut.updatePreference(\.positiveBehaviors, value: false)

        #expect(sut.notificationPreferences?.positiveBehaviors == false)
    }
}

// MARK: - StudentSetupViewModel Tests

@Suite("StudentSetupViewModel")
@MainActor
struct StudentSetupViewModelTests {

    @Test("canSubmit validates all fields")
    func canSubmitValidation() {
        let sut = StudentSetupViewModel()

        #expect(sut.canSubmit == false)

        sut.name = "Alice"
        #expect(sut.canSubmit == false)

        sut.classCode = "ABC123"
        #expect(sut.canSubmit == true)

        sut.isLoading = true
        #expect(sut.canSubmit == false)
    }

    @Test("Fails with empty name")
    func emptyName() async {
        let sut = StudentSetupViewModel()
        sut.name = ""
        sut.classCode = "ABC123"

        await sut.createStudentProfile(userId: UUID())

        #expect(sut.errorMessage == "Please enter your name")
        #expect(sut.isComplete == false)
        #expect(sut.isLoading == false)
    }

    @Test("Fails with empty class code")
    func emptyClassCode() async {
        let sut = StudentSetupViewModel()
        sut.name = "Alice"
        sut.classCode = ""

        await sut.createStudentProfile(userId: UUID())

        #expect(sut.errorMessage == "Please enter a class code")
        #expect(sut.isComplete == false)
    }

    @Test("Fails with invalid class code")
    func invalidClassCode() async throws {
        let mockSupabase = MockSupabaseService()
        mockSupabase.fetchClassByCodeResult = .success(nil)

        let sut = StudentSetupViewModel(supabaseService: mockSupabase)
        sut.name = "Alice"
        sut.classCode = "INVALID"

        await sut.createStudentProfile(userId: UUID())

        #expect(sut.errorMessage == "Invalid class code. Please check with your teacher.")
        #expect(sut.isComplete == false)
    }

    @Test("Creates student profile successfully via direct insert")
    func createSuccessDirect() async throws {
        let mockSupabase = MockSupabaseService()
        let classObj = Class(id: UUID(), teacherId: UUID(), name: "Test Class", classCode: "ABC123")
        mockSupabase.fetchClassByCodeResult = .success(classObj)

        let sut = StudentSetupViewModel(supabaseService: mockSupabase)
        sut.name = "Alice"
        sut.classCode = "abc123"

        await sut.createStudentProfile(userId: UUID())

        #expect(sut.isComplete == true)
        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
    }

    @Test("Sets error when class lookup fails")
    func classLookupFailure() async throws {
        let mockSupabase = MockSupabaseService()
        // Not setting fetchClassByCodeResult — default mock throws MockError.unexpectedCall
        // which is caught by the outer catch block

        let sut = StudentSetupViewModel(supabaseService: mockSupabase)
        sut.name = "Alice"
        sut.classCode = "abc123"

        await sut.createStudentProfile(userId: UUID())

        #expect(sut.errorMessage != nil)
        #expect(sut.isComplete == false)
        #expect(sut.isLoading == false)
    }
}
