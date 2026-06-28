//
//  StudentProfileViewModel.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation
import Combine

@MainActor
class StudentProfileViewModel: ObservableObject {
    private let behaviorService = BehaviorService()
    
    @Published var events: [BehaviorEvent] = []
    @Published var filter: FeedFilter = .today
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var showingLogBehavior: Bool = false
    
    private let student: Student
    
    init(student: Student) {
        self.student = student
        fetchEvents()
    }
    
    func fetchEvents() {
        Task {
            await performFetch()
        }
    }
    
    private func performFetch() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allEvents = try await behaviorService.fetchEvents(for: student.id)
            let dateRange = filter.dateRange
            
            // Filter events based on the selected time range
            events = allEvents.filter { event in
                return event.createdAt >= dateRange.start && event.createdAt < dateRange.end
            }
        } catch {
            // Provide user-friendly error message without exposing raw Supabase errors
            errorMessage = "Unable to load behavior history. Please check your connection and try again."
            events = []
        }
        
        isLoading = false
    }
    
    func setFilter(_ newFilter: FeedFilter) {
        guard filter != newFilter else { return }
        
        filter = newFilter
        fetchEvents()
    }
    
    func refreshEvents() {
        fetchEvents()
    }
    
    func showLogBehaviorSheet() {
        showingLogBehavior = true
    }
    
    // MARK: - Computed Properties
    
    var studentName: String {
        return student.name
    }
    
    var studentPointTotal: Int {
        return student.pointTotal
    }
    
    var totalPositiveEvents: Int {
        return events.filter { $0.isPositive }.count
    }
    
    var totalNegativeEvents: Int {
        return events.filter { !$0.isPositive }.count
    }
    
    var netPointsThisPeriod: Int {
        return events.reduce(0) { $0 + $1.points }
    }
}
