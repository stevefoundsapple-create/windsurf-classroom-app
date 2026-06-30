import Foundation

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

    static func configuredForTesting() -> MockBehaviorService {
        let mock = MockBehaviorService()
        if UITestHarness.isErrorState {
            mock.fetchEventsResult = .failure(NSError(domain: "mock", code: 500))
            mock.fetchEventsForClassResult = .failure(NSError(domain: "mock", code: 500))
        } else if UITestHarness.isEmptyState {
            mock.fetchEventsResult = .success([])
            mock.fetchEventsForClassResult = .success([])
        } else {
            mock.fetchEventsResult = .success(TestData.makeBehaviorEvents())
            mock.fetchEventsForClassResult = .success(TestData.makeBehaviorEvents())
        }
        return mock
    }
}
