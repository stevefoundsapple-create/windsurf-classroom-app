import Foundation

class StudentService: StudentServiceProtocol {
    private let supabaseService: SupabaseServiceProtocol
    private let cache: OfflineCacheService
    
    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared, cache: OfflineCacheService = .shared) {
        self.supabaseService = supabaseService
        self.cache = cache
    }
    
    func fetchStudents(classId: UUID) async throws -> [Student] {
        let key = "students_\(classId)"
        
        if let cached: [Student] = cache.fetch([Student].self, key: key) {
            return cached
        }
        
        do {
            let students = try await supabaseService.fetchStudents(classId: classId)
            cache.cache(students, key: key)
            return students
        } catch {
            if let cached: [Student] = cache.fetch([Student].self, key: key) {
                return cached
            }
            throw error
        }
    }
    
    func fetchStudent(id: UUID) async throws -> Student {
        let key = "student_\(id)"
        
        if let cached: Student = cache.fetch(Student.self, key: key) {
            return cached
        }
        
        do {
            let student = try await supabaseService.fetchStudent(id: id)
            cache.cache(student, key: key)
            return student
        } catch {
            if let cached: Student = cache.fetch(Student.self, key: key) {
                return cached
            }
            throw error
        }
    }
    
    func createStudent(_ student: Student) async throws {
        try await supabaseService.createStudent(student)
        cache.invalidate(key: "students_\(student.classId)")
    }
    
    func updateStudentPoints(studentId: UUID, newTotal: Int) async throws {
        try await supabaseService.updateStudentPoints(studentId: studentId, newTotal: newTotal)
        cache.invalidate(key: "student_\(studentId)")
        cache.invalidate(key: "students_")
    }
}
