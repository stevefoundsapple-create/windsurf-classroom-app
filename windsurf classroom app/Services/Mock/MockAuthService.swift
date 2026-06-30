import Foundation
import Supabase

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

    static func configuredForTesting() -> MockAuthService {
        let mock = MockAuthService()
        let userId = UUID()
        let session = TestData.makeSession(userId: userId)
        mock.signInResult = .success(session)
        mock.currentSessionResult = .success(session)

        switch UITestHarness.mockRole {
        case .teacher:
            mock.fetchProfileResult = .success(TestData.makeTeacherProfile(userId: userId))
        case .parent:
            mock.fetchProfileResult = .success(TestData.makeParentProfile(userId: userId))
        case .student:
            mock.fetchProfileResult = .success(TestData.makeStudentProfile(userId: userId))
        case .none:
            mock.fetchProfileResult = .success(TestData.makeTeacherProfile(userId: userId))
        case nil:
            mock.fetchProfileResult = .success(TestData.makeTeacherProfile(userId: userId))
        }

        return mock
    }
}
