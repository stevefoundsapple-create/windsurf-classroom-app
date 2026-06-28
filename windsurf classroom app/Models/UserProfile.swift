//
//  UserProfile.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let role: UserRole
    let classId: UUID?
    
    enum UserRole: String, Codable, CaseIterable {
        case teacher = "teacher"
        case student = "student"
        case parent = "parent"
    }
}
