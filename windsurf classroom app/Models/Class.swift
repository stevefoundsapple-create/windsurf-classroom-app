//
//  Class.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/08.
//

import Foundation

struct Class: Codable, Identifiable {
    let id: UUID
    let teacherId: UUID
    let name: String
    let classCode: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case teacherId = "teacher_id"
        case classCode = "class_code"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString.lowercased(), forKey: .id)
        try container.encode(teacherId.uuidString.lowercased(), forKey: .teacherId)
        try container.encode(name, forKey: .name)
        try container.encode(classCode, forKey: .classCode)
    }
}
