//
//  FeedFilter.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation

enum FeedFilter: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case all = "All Time"
    
    var localizedDisplayName: String {
        rawValue.localized()
    }
    
    var dateRange: (start: Date, end: Date) {
        let now = Date()
        let calendar = Calendar.current
        
        switch self {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return (startOfDay, endOfDay)
            
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
            return (startOfWeek, endOfWeek)
            
        case .all:
            // Return a very early date to get all events
            let distantPast = Date.distantPast
            return (distantPast, now)
        }
    }
}
