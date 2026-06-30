import Foundation
import os.log

class BehaviorService: BehaviorServiceProtocol {
    private let supabaseService: SupabaseServiceProtocol
    private let studentService: StudentServiceProtocol
    private let cache: OfflineCacheService
    private let logger = Logger(subsystem: "ClassroomApp", category: "BehaviorService")
    
    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared, studentService: StudentServiceProtocol = StudentService(), cache: OfflineCacheService = .shared) {
        self.supabaseService = supabaseService
        self.studentService = studentService
        self.cache = cache
    }
    
    func logEvent(
        studentId: UUID,
        teacherId: UUID,
        category: String,
        isPositive: Bool,
        points: Int,
        note: String? = nil
    ) async throws {
        logger.info("Starting logEvent - studentId: \(studentId), teacherId: \(teacherId), points: \(points)")
        
        let event = BehaviorEvent(
            id: UUID(),
            studentId: studentId,
            teacherId: teacherId,
            category: category,
            isPositive: isPositive,
            points: points,
            note: note,
            createdAt: Date()
        )
        
        logger.info("Logging behavior event to database")
        try await supabaseService.logBehaviorEvent(event)
        logger.info("Successfully logged behavior event")
        
        logger.info("Fetching student to update points")
        let student = try await supabaseService.fetchStudent(id: studentId)
        let newTotal = student.pointTotal + points
        logger.info("Updating student points from \(student.pointTotal) to \(newTotal)")
        try await supabaseService.updateStudentPoints(studentId: studentId, newTotal: newTotal)
        logger.info("Successfully updated student points")
        
        do {
            try await supabaseService.triggerBehaviorNotification(
                eventId: event.id,
                studentId: studentId,
                category: category,
                isPositive: isPositive,
                points: points,
                note: note
            )
            logger.info("Successfully triggered notification for event: \(event.id)")
        } catch {
            logger.error("Failed to trigger notification: \(error.localizedDescription)")
        }
        
        cache.invalidate(key: "events_\(studentId)")
        cache.invalidate(key: "student_\(studentId)")
    }
    
    func fetchEvents(for studentId: UUID, limit: Int = 50) async throws -> [BehaviorEvent] {
        let key = "events_\(studentId)_\(limit)"
        
        if let cached: [BehaviorEvent] = cache.fetch([BehaviorEvent].self, key: key) {
            return cached
        }
        
        do {
            let events = try await supabaseService.fetchBehaviorEvents(studentId: studentId, limit: limit)
            cache.cache(events, key: key)
            return events
        } catch {
            if let cached: [BehaviorEvent] = cache.fetch([BehaviorEvent].self, key: key) {
                return cached
            }
            throw error
        }
    }
    
    func fetchEventsForClass(classId: UUID, limit: Int = 100) async throws -> [BehaviorEvent] {
        let key = "events_class_\(classId)_\(limit)"
        
        if let cached: [BehaviorEvent] = cache.fetch([BehaviorEvent].self, key: key) {
            return cached
        }
        
        do {
            let events = try await supabaseService.fetchBehaviorEventsForClass(classId: classId, limit: limit)
            cache.cache(events, key: key)
            return events
        } catch {
            if let cached: [BehaviorEvent] = cache.fetch([BehaviorEvent].self, key: key) {
                return cached
            }
            throw error
        }
    }
}
