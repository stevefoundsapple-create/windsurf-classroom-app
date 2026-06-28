//
//  NotificationPreferences.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/06/06.
//

import Foundation

struct NotificationPreferences: Codable {
    let userId: UUID
    var positiveBehaviors: Bool
    var negativeBehaviors: Bool
    var weeklySummaries: Bool
    var quietHoursEnabled: Bool
    var quietHoursStart: String // Format: "HH:mm"
    var quietHoursEnd: String // Format: "HH:mm"
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case positiveBehaviors = "positive_behaviors"
        case negativeBehaviors = "negative_behaviors"
        case weeklySummaries = "weekly_summaries"
        case quietHoursEnabled = "quiet_hours_enabled"
        case quietHoursStart = "quiet_hours_start"
        case quietHoursEnd = "quiet_hours_end"
    }
    
    init(userId: UUID) {
        self.userId = userId
        self.positiveBehaviors = true
        self.negativeBehaviors = true
        self.weeklySummaries = true
        self.quietHoursEnabled = false
        self.quietHoursStart = "22:00"
        self.quietHoursEnd = "07:00"
    }
}
