//
//  Student.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation

struct Student: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    let name: String
    let classId: UUID
    let parentId: UUID?
    var pointTotal: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
        case classId = "class_id"
        case parentId = "parent_id"
        case pointTotal = "point_total"
    }
}
