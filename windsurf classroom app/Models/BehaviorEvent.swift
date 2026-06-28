//
//  BehaviorEvent.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation

struct BehaviorEvent: Codable, Identifiable {
    let id: UUID
    let studentId: UUID
    let teacherId: UUID
    let category: String
    let isPositive: Bool
    let points: Int
    let note: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, category, note, points
        case studentId = "student_id"
        case teacherId = "teacher_id"
        case isPositive = "is_positive"
        case createdAt = "created_at"
    }
}
