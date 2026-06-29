import Foundation

protocol BehaviorServiceProtocol: AnyObject {
    func logEvent(
        studentId: UUID,
        teacherId: UUID,
        category: String,
        isPositive: Bool,
        points: Int,
        note: String?
    ) async throws

    func fetchEvents(for studentId: UUID, limit: Int) async throws -> [BehaviorEvent]
    func fetchEventsForClass(classId: UUID, limit: Int) async throws -> [BehaviorEvent]
}

extension BehaviorServiceProtocol {
    func fetchEvents(for studentId: UUID) async throws -> [BehaviorEvent] {
        try await fetchEvents(for: studentId, limit: 50)
    }
}
