import Foundation
import Supabase
import os.log

class CachedSupabaseService: SupabaseServiceProtocol {
    static let shared = CachedSupabaseService()

    private let inner: SupabaseServiceProtocol
    private let cache = CacheService.shared
    private let offlineQueue = OfflineOperationQueue.shared
    private let logger = Logger(subsystem: "ClassroomApp", category: "CachedSupabaseService")
    private let networkMonitor: NetworkMonitor

    private init(
        inner: SupabaseServiceProtocol = SupabaseService.shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.inner = inner
        self.networkMonitor = networkMonitor
        observeReachability()

        if networkMonitor.isConnected {
            replayOnLaunch()
        }
    }

    private func replayOnLaunch() {
        Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await self.replayOfflineOperations()
        }
    }

    var realtime: RealtimeClientV2 {
        inner.realtime
    }

    // MARK: - Reachability

    private var replayTask: Task<Void, Never>?
    private var hasReplayed = false

    private func observeReachability() {
        replayTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .networkStatusChanged) {
                guard let self else { return }
                if self.networkMonitor.isConnected && !self.hasReplayed {
                    self.hasReplayed = true
                    await self.replayOfflineOperations()
                } else if !self.networkMonitor.isConnected {
                    self.hasReplayed = false
                }
            }
        }
    }

    private func replayOfflineOperations() async {
        let ops = await offlineQueue.dequeueAll()
        guard !ops.isEmpty else { return }
        logger.info("Replaying \(ops.count) queued offline operations")

        for op in ops {
            do {
                switch op.type {
                case "logBehaviorEvent":
                    let event = try JSONDecoder().decode(BehaviorEvent.self, from: op.data)
                    try await inner.logBehaviorEvent(event)
                    let student = try await inner.fetchStudent(id: event.studentId)
                    try await inner.updateStudentPoints(studentId: event.studentId, newTotal: student.pointTotal + event.points)
                    logger.info("Replayed offline event for student \(event.studentId)")
                default:
                    break
                }
            } catch {
                logger.error("Failed to replay offline operation \(op.id): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws -> Session {
        try await inner.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await inner.signOut()
        await cache.clearAll()
    }

    func getCurrentSession() async throws -> Session? {
        try await inner.getCurrentSession()
    }

    func getCurrentSessionUserId() async throws -> UUID? {
        try await inner.getCurrentSessionUserId()
    }

    // MARK: - Classes (cached)

    func fetchClass(id: UUID) async throws -> Class {
        let key = "class_\(id)"
        if let cached: Class = await cache.load(key, maxAge: 3600) {
            return cached
        }
        let value = try await inner.fetchClass(id: id)
        await cache.save(value, for: key)
        return value
    }

    func fetchClassByTeacherId(teacherId: UUID) async throws -> Class? {
        let key = "class_teacher_\(teacherId)"
        if let cached: Class = await cache.load(key, maxAge: 3600) {
            return cached
        }
        let value = try await inner.fetchClassByTeacherId(teacherId: teacherId)
        if let value { await cache.save(value, for: key) }
        return value
    }

    func fetchClassByCode(_ code: String) async throws -> Class? {
        let key = "class_code_\(code)"
        if let cached: Class = await cache.load(key, maxAge: 3600) {
            return cached
        }
        let value = try await inner.fetchClassByCode(code)
        if let value { await cache.save(value, for: key) }
        return value
    }

    // MARK: - Profiles (cached)

    func fetchProfile(userId: UUID) async throws -> UserProfile {
        let key = "profile_\(userId)"
        if let cached: UserProfile = await cache.load(key, maxAge: 3600) {
            return cached
        }
        let value = try await inner.fetchProfile(userId: userId)
        await cache.save(value, for: key)
        return value
    }

    // MARK: - Students (cached)

    func fetchStudents(classId: UUID) async throws -> [Student] {
        let key = "students_\(classId)"
        if let cached: [Student] = await cache.load(key, maxAge: 3600) {
            return cached
        }
        let value = try await inner.fetchStudents(classId: classId)
        await cache.save(value, for: key)
        return value
    }

    func fetchStudent(id: UUID) async throws -> Student {
        let key = "student_\(id)"
        if let cached: Student = await cache.load(key, maxAge: 3600) {
            return cached
        }
        let value = try await inner.fetchStudent(id: id)
        await cache.save(value, for: key)
        return value
    }

    func fetchStudentByParentId(parentId: UUID) async throws -> Student? {
        let key = "student_parent_\(parentId)"
        if let cached: Student = await cache.load(key, maxAge: 3600) {
            return cached
        }
        let value = try await inner.fetchStudentByParentId(parentId: parentId)
        if let value { await cache.save(value, for: key) }
        return value
    }

    func fetchStudentByUserId(userId: UUID) async throws -> Student? {
        let key = "student_user_\(userId)"
        if let cached: Student = await cache.load(key, maxAge: 3600) {
            return cached
        }
        let value = try await inner.fetchStudentByUserId(userId: userId)
        if let value { await cache.save(value, for: key) }
        return value
    }

    // MARK: - Behavior Events (cached)

    func fetchBehaviorEvents(studentId: UUID, limit: Int) async throws -> [BehaviorEvent] {
        let key = "events_\(studentId)_\(limit)"
        if let cached: [BehaviorEvent] = await cache.load(key, maxAge: 300) {
            return cached
        }
        let value = try await inner.fetchBehaviorEvents(studentId: studentId, limit: limit)
        await cache.save(value, for: key)
        return value
    }

    func fetchBehaviorEventsForClass(classId: UUID, limit: Int) async throws -> [BehaviorEvent] {
        try await inner.fetchBehaviorEventsForClass(classId: classId, limit: limit)
    }

    // MARK: - Behavior Categories (cached)

    func fetchBehaviorCategories(classId: UUID) async throws -> [BehaviorCategory] {
        let key = "categories_\(classId)"
        if let cached: [BehaviorCategory] = await cache.load(key, maxAge: 3600) {
            return cached
        }
        let value = try await inner.fetchBehaviorCategories(classId: classId)
        await cache.save(value, for: key)
        return value
    }

    // MARK: - Writes (try network, queue offline)

    func logBehaviorEvent(_ event: BehaviorEvent) async throws {
        if networkMonitor.isConnected {
            do {
                try await inner.logBehaviorEvent(event)
                await cache.remove("events_\(event.studentId)_50")
                logger.info("Logged behavior event online")
                return
            } catch where !networkMonitor.isConnected {
                // Network dropped mid-call, fall through to queue
            }
        }
        let data = try JSONEncoder().encode(event)
        await offlineQueue.enqueue(type: "logBehaviorEvent", data: data)
        logger.info("Queued behavior event for offline send")
    }

    func updateStudentPoints(studentId: UUID, newTotal: Int) async throws {
        if networkMonitor.isConnected {
            try await inner.updateStudentPoints(studentId: studentId, newTotal: newTotal)
            await cache.remove("student_\(studentId)")
            return
        }
        throw OfflineError.updateNotSupportedOffline
    }

    // MARK: - Other reads (passthrough, no cache)

    func searchStudentsByName(_ name: String) async throws -> [Student] {
        try await inner.searchStudentsByName(name)
    }

    func fetchStudentsByParentId(parentId: UUID) async throws -> [Student] {
        try await inner.fetchStudentsByParentId(parentId: parentId)
    }

    func fetchNotificationPreferences(userId: UUID) async throws -> NotificationPreferences? {
        try await inner.fetchNotificationPreferences(userId: userId)
    }

    // MARK: - Other writes (passthrough, require network)

    func createClass(_ classObj: Class) async throws {
        try await inner.createClass(classObj)
    }

    func createClassViaRPC(_ classObj: Class) async throws {
        try await inner.createClassViaRPC(classObj)
    }

    func updateProfileClassId(userId: UUID, classId: UUID) async throws {
        try await inner.updateProfileClassId(userId: userId, classId: classId)
    }

    func createProfile(_ profile: UserProfile) async throws {
        try await inner.createProfile(profile)
    }

    func createStudent(_ student: Student) async throws {
        try await inner.createStudent(student)
    }

    func createStudentViaRPC(_ student: Student) async throws {
        try await inner.createStudentViaRPC(student)
    }

    func createBehaviorCategory(_ category: BehaviorCategory) async throws {
        try await inner.createBehaviorCategory(category)
        await cache.remove("categories_\(category.classId)")
    }

    func updateBehaviorCategory(_ category: BehaviorCategory) async throws {
        try await inner.updateBehaviorCategory(category)
        await cache.remove("categories_\(category.classId)")
    }

    func deleteBehaviorCategory(id: UUID) async throws {
        try await inner.deleteBehaviorCategory(id: id)
    }

    func saveDeviceToken(_ token: String, forUserId userId: UUID) async throws {
        try await inner.saveDeviceToken(token, forUserId: userId)
    }

    func deleteDeviceToken(_ token: String, forUserId userId: UUID) async throws {
        try await inner.deleteDeviceToken(token, forUserId: userId)
    }

    func linkParentToStudent(parentId: UUID, studentId: UUID) async throws {
        try await inner.linkParentToStudent(parentId: parentId, studentId: studentId)
    }

    func unlinkParentFromStudent(studentId: UUID) async throws {
        try await inner.unlinkParentFromStudent(studentId: studentId)
    }

    func createNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        try await inner.createNotificationPreferences(preferences)
    }

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        try await inner.updateNotificationPreferences(preferences)
    }

    func triggerBehaviorNotification(eventId: UUID, studentId: UUID, category: String, isPositive: Bool, points: Int, note: String?) async throws {
        try await inner.triggerBehaviorNotification(eventId: eventId, studentId: studentId, category: category, isPositive: isPositive, points: points, note: note)
    }

    func deleteAccount(userId: UUID) async throws {
        try await inner.deleteAccount(userId: userId)
    }
}

enum OfflineError: LocalizedError {
    case updateNotSupportedOffline

    var errorDescription: String? {
        switch self {
        case .updateNotSupportedOffline:
            return "This action requires an internet connection.".localized()
        }
    }
}

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
