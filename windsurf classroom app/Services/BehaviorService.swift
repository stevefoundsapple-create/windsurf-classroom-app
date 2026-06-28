//
//  BehaviorService.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation
import os.log

class BehaviorService {
    private let supabaseService = SupabaseService.shared
    private let studentService = StudentService()
    private let logger = Logger(subsystem: "ClassroomApp", category: "BehaviorService")
    
    func logEvent(
        studentId: UUID,
        teacherId: UUID,
        category: String,
        isPositive: Bool,
        points: Int,
        note: String? = nil
    ) async throws {
        logger.info("Starting logEvent - studentId: \(studentId), teacherId: \(teacherId), points: \(points)")
        
        // Create the behavior event
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
        
        // Log the event
        logger.info("Logging behavior event to database")
        try await supabaseService.logBehaviorEvent(event)
        logger.info("Successfully logged behavior event")
        
        // Update student's point total
        logger.info("Fetching student to update points")
        let student = try await supabaseService.fetchStudent(id: studentId)
        let newTotal = student.pointTotal + points
        logger.info("Updating student points from \(student.pointTotal) to \(newTotal)")
        try await supabaseService.updateStudentPoints(studentId: studentId, newTotal: newTotal)
        logger.info("Successfully updated student points")
        
        // TODO: Trigger notification to parent
        // This will be implemented when NotificationService is created
    }
    
    func fetchEvents(for studentId: UUID, limit: Int = 50) async throws -> [BehaviorEvent] {
        return try await supabaseService.fetchBehaviorEvents(studentId: studentId, limit: limit)
    }
    
    func fetchEventsForClass(classId: UUID, limit: Int = 100) async throws -> [BehaviorEvent] {
        return try await supabaseService.fetchBehaviorEventsForClass(classId: classId, limit: limit)
    }
}
