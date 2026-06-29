import Foundation

protocol StudentServiceProtocol: AnyObject {
    func fetchStudents(classId: UUID) async throws -> [Student]
    func fetchStudent(id: UUID) async throws -> Student
    func createStudent(_ student: Student) async throws
    func updateStudentPoints(studentId: UUID, newTotal: Int) async throws
}
