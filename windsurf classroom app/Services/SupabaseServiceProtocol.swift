import Foundation
import Supabase

protocol SupabaseServiceProtocol: AnyObject {
    func signIn(email: String, password: String) async throws -> Session
    func signOut() async throws
    func getCurrentSession() async throws -> Session?
    func getCurrentSessionUserId() async throws -> UUID?
    var realtime: RealtimeClientV2 { get }
    func createClass(_ classObj: Class) async throws
    func createClassViaRPC(_ classObj: Class) async throws
    func fetchClass(id: UUID) async throws -> Class
    func fetchClassByTeacherId(teacherId: UUID) async throws -> Class?
    func fetchClassByCode(_ code: String) async throws -> Class?
    func updateProfileClassId(userId: UUID, classId: UUID) async throws

    func fetchProfile(userId: UUID) async throws -> UserProfile
    func createProfile(_ profile: UserProfile) async throws

    func fetchStudents(classId: UUID) async throws -> [Student]
    func fetchStudent(id: UUID) async throws -> Student
    func fetchStudentByParentId(parentId: UUID) async throws -> Student?
    func fetchStudentByUserId(userId: UUID) async throws -> Student?
    func createStudent(_ student: Student) async throws
    func createStudentViaRPC(_ student: Student) async throws
    func updateStudentPoints(studentId: UUID, newTotal: Int) async throws

    func logBehaviorEvent(_ event: BehaviorEvent) async throws
    func fetchBehaviorEvents(studentId: UUID, limit: Int) async throws -> [BehaviorEvent]
    func fetchBehaviorEventsForClass(classId: UUID, limit: Int) async throws -> [BehaviorEvent]

    func fetchBehaviorCategories(classId: UUID) async throws -> [BehaviorCategory]
    func createBehaviorCategory(_ category: BehaviorCategory) async throws
    func updateBehaviorCategory(_ category: BehaviorCategory) async throws
    func deleteBehaviorCategory(id: UUID) async throws

    func saveDeviceToken(_ token: String, forUserId userId: UUID) async throws
    func deleteDeviceToken(_ token: String, forUserId userId: UUID) async throws

    func searchStudentsByName(_ name: String) async throws -> [Student]
    func linkParentToStudent(parentId: UUID, studentId: UUID) async throws
    func unlinkParentFromStudent(studentId: UUID) async throws
    func fetchStudentsByParentId(parentId: UUID) async throws -> [Student]

    func fetchNotificationPreferences(userId: UUID) async throws -> NotificationPreferences?
    func createNotificationPreferences(_ preferences: NotificationPreferences) async throws
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws

    func triggerBehaviorNotification(eventId: UUID, studentId: UUID, category: String, isPositive: Bool, points: Int, note: String?) async throws

    func deleteAccount(userId: UUID) async throws
}
