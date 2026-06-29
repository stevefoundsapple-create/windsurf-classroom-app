//
//  ParentReportsViewModel.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/03.
//

import Foundation
import Combine
import os.log

@MainActor
class ParentReportsViewModel: ObservableObject {
    private let supabaseService: SupabaseServiceProtocol
    private let logger = Logger(subsystem: "ClassroomApp", category: "ParentReports")
    
    @Published var child: Student?
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }
    @Published var weeklyPointTotal: Int = 0
    @Published var weeklyPositiveEvents: Int = 0
    @Published var weeklyNegativeEvents: Int = 0
    @Published var weeklyStartDate: String = ""
    @Published var weeklyEndDate: String = ""
    @Published var weeklyTrend: [DayTrend] = []
    @Published var previousWeeks: [WeekSummary] = []
    
    /// Fetches reports data for the parent's child
    func fetchReports(parentId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch the child associated with this parent
            child = try await supabaseService.fetchStudentByParentId(parentId: parentId)
            
            guard let child = child else {
                logger.warning("No child found for parent: \(parentId)")
                isLoading = false
                return
            }
            
            // Fetch events for the child for the past 8 weeks
            let fetchedEvents = try await supabaseService.fetchBehaviorEvents(
                studentId: child.id, 
                limit: 500
            )
            
            // Process the data
            processReportsData(events: fetchedEvents)
            
        } catch {
            logger.error("Failed to fetch reports: \(error.localizedDescription)")
            errorMessage = "Unable to load reports. Please check your connection and try again."
        }
        
        isLoading = false
    }
    
    /// Refreshes the reports data
    func refreshReports(parentId: UUID) async {
        await fetchReports(parentId: parentId)
    }
    
    /// Processes events data to generate reports
    private func processReportsData(events: [BehaviorEvent]) {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate current week dates
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? today
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        weeklyStartDate = formatter.string(from: weekStart)
        weeklyEndDate = formatter.string(from: weekEnd)
        
        // Filter current week events
        let currentWeekEvents = events.filter { event in
            event.createdAt >= weekStart && event.createdAt <= weekEnd
        }
        
        // Calculate weekly totals
        weeklyPointTotal = currentWeekEvents.reduce(0) { $0 + $1.points }
        weeklyPositiveEvents = currentWeekEvents.filter { $0.isPositive }.count
        weeklyNegativeEvents = currentWeekEvents.filter { !$0.isPositive }.count
        
        // Generate weekly trend (last 7 days)
        weeklyTrend = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let dayEvents = events.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
            let dayPoints = dayEvents.reduce(0) { $0 + $1.points }
            
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            
            return DayTrend(
                day: dayFormatter.string(from: date),
                points: dayPoints
            )
        }.reversed()
        
        // Generate previous weeks summaries
        var weeks: [WeekSummary] = []
        for weekOffset in 1...4 {
            if let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: weekStart),
               let previousWeekEnd = calendar.date(byAdding: .day, value: 6, to: previousWeekStart) {
                
                let previousWeekEvents = events.filter { event in
                    event.createdAt >= previousWeekStart && event.createdAt <= previousWeekEnd
                }
                
                let positiveCount = previousWeekEvents.filter { $0.isPositive }.count
                let negativeCount = previousWeekEvents.filter { !$0.isPositive }.count
                let totalPoints = previousWeekEvents.reduce(0) { $0 + $1.points }
                
                let weekFormatter = DateFormatter()
                weekFormatter.dateFormat = "MMM d"
                
                let weekSummary = WeekSummary(
                    id: UUID(),
                    dateRange: "\(weekFormatter.string(from: previousWeekStart)) - \(weekFormatter.string(from: previousWeekEnd))",
                    positiveEvents: positiveCount,
                    negativeEvents: negativeCount,
                    totalPoints: totalPoints
                )
                
                weeks.append(weekSummary)
            }
        }
        
        previousWeeks = weeks
    }
}

// MARK: - Supporting Models

struct DayTrend: Identifiable {
    let id = UUID()
    let day: String
    let points: Int
}

struct WeekSummary: Identifiable {
    let id: UUID
    let dateRange: String
    let positiveEvents: Int
    let negativeEvents: Int
    let totalPoints: Int
}
