import Foundation

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

    static func configuredForTesting() -> MockStudentService {
        let mock = MockStudentService()
        if UITestHarness.isErrorState {
            mock.fetchStudentsResult = .failure(NSError(domain: "mock", code: 500))
            mock.fetchStudentResult = .failure(NSError(domain: "mock", code: 500))
        } else if UITestHarness.isEmptyState {
            mock.fetchStudentsResult = .success([])
            mock.fetchStudentResult = .failure(NSError(domain: "mock", code: 404))
        } else {
            let students = TestData.makeStudents()
            mock.fetchStudentsResult = .success(students)
            mock.fetchStudentResult = .success(students[0])
        }
        return mock
    }
}
