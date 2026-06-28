//
//  BehaviorCategory.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation

struct BehaviorCategory: Codable, Identifiable {
    let id: UUID
    let classId: UUID
    let label: String
    let isPositive: Bool
    let points: Int
    
    enum CodingKeys: String, CodingKey {
        case id, label, points
        case classId = "class_id"
        case isPositive = "is_positive"
    }
    
    // Default categories for a class
    static let defaultPositiveCategories: [BehaviorCategory] = [
        BehaviorCategory(id: UUID(), classId: UUID(), label: "Participated", isPositive: true, points: 2),
        BehaviorCategory(id: UUID(), classId: UUID(), label: "Helped Others", isPositive: true, points: 3),
        BehaviorCategory(id: UUID(), classId: UUID(), label: "Excellent Work", isPositive: true, points: 5),
        BehaviorCategory(id: UUID(), classId: UUID(), label: "On Task", isPositive: true, points: 1),
        BehaviorCategory(id: UUID(), classId: UUID(), label: "Creative Thinking", isPositive: true, points: 3)
    ]
    
    static let defaultNegativeCategories: [BehaviorCategory] = [
        BehaviorCategory(id: UUID(), classId: UUID(), label: "Off-task", isPositive: false, points: -2),
        BehaviorCategory(id: UUID(), classId: UUID(), label: "Disruptive", isPositive: false, points: -3),
        BehaviorCategory(id: UUID(), classId: UUID(), label: "Missing Work", isPositive: false, points: -2),
        BehaviorCategory(id: UUID(), classId: UUID(), label: "Unprepared", isPositive: false, points: -1)
    ]
}
