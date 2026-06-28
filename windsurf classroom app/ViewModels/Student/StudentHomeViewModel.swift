//
//  StudentHomeViewModel.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/02.
//

import Foundation
import Combine
import Supabase
import os.log

@MainActor
class StudentHomeViewModel: ObservableObject {
    private let supabaseService = SupabaseService.shared
    private let logger = Logger(subsystem: "ClassroomApp", category: "StudentHome")
    
    private var realtimeChannel: RealtimeChannelV2?
    private var realtimeSubscription: RealtimeSubscription?
    internal var currentStudentId: UUID?
    
    @Published var events: [BehaviorEvent] = []
    @Published var pointTotal: Int = 0
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var showConfetti: Bool = false
    @Published var needsSetup: Bool = false
    
    /// Loads behavior events for the current student
    func fetchEvents(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First, fetch the student record using the user ID
            guard let student = try await supabaseService.fetchStudentByUserId(userId: userId) else {
                logger.error("No student record found for user: \(userId)")
                needsSetup = true
                isLoading = false
                return
            }
            
            // Store the student ID for realtime subscription
            currentStudentId = student.id
            
            // Then fetch events using the student record ID
            let fetchedEvents = try await supabaseService.fetchBehaviorEvents(studentId: student.id, limit: 100)
            events = fetchedEvents
            
            // Use the point total from the student record
            pointTotal = student.pointTotal
            
            logger.info("Fetched \(fetchedEvents.count) events for student: \(student.name) (\(student.id))")
        } catch {
            logger.error("Failed to fetch events: \(error.localizedDescription)")
            // Provide user-friendly error message without exposing raw Supabase errors
            errorMessage = "Unable to load your data. Please check your connection and try again."
        }
        
        isLoading = false
    }
    
    /// Refreshes the events data
    func refreshEvents(userId: UUID) async {
        needsSetup = false
        await fetchEvents(userId: userId)
    }
    
    /// Called when student profile setup is complete
    func setupComplete(userId: UUID) {
        needsSetup = false
        Task {
            await fetchEvents(userId: userId)
        }
    }
    
    /// Subscribes to realtime updates for the student's behavior events
    func subscribeToRealtime(studentId: UUID) {
        guard let studentId = currentStudentId else {
            logger.error("Cannot subscribe: no student ID available")
            return
        }
        
        logger.info("Subscribing to realtime updates for student: \(studentId)")
        
        // Create a unique channel for this student
        let channelName = "student_\(studentId.uuidString)"
        realtimeChannel = supabaseService.realtime.channel(channelName)
        
        guard let channel = realtimeChannel else {
            logger.error("Failed to create realtime channel")
            return
        }
        
        // Subscribe to INSERT events on behavior_events table for this student
        // Filter syntax: column_name=eq.value
        let filter = "student_id=eq.\(studentId.uuidString)"
        realtimeSubscription = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "behavior_events",
            filter: filter
        ) { [weak self] change in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleNewEvent(change.record)
            }
        }
        
        // Start the subscription
        Task {
            do {
                try await channel.subscribeWithError()
                logger.info("Realtime subscription successful for student: \(studentId)")
            } catch {
                logger.error("Failed to subscribe to realtime: \(error.localizedDescription)")
            }
        }
    }
    
    /// Unsubscribes from realtime updates
    func unsubscribeFromRealtime() {
        logger.info("Unsubscribing from realtime updates")
        
        Task {
            if let subscription = realtimeSubscription {
                subscription.cancel()
                realtimeSubscription = nil
            }
            
            if let channel = realtimeChannel {
                await channel.unsubscribe()
                realtimeChannel = nil
            }
            
            currentStudentId = nil
            logger.info("Realtime unsubscription complete")
        }
    }
    
    /// Handles a new behavior event received from realtime
    private func handleNewEvent(_ record: [String: Any]) {
        logger.info("Received new event from realtime")
        
        do {
            // Decode the record into a BehaviorEvent
            let jsonData = try JSONSerialization.data(withJSONObject: record)
            let newEvent = try JSONDecoder().decode(BehaviorEvent.self, from: jsonData)
            
            // Add the new event to the beginning of the array
            events.insert(newEvent, at: 0)
            
            // Update point total
            pointTotal += newEvent.points
            
            // Show confetti for positive events
            if newEvent.isPositive {
                showConfetti = true
                // Hide confetti after animation
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    showConfetti = false
                }
            }
            
            logger.info("Successfully processed new event: \(newEvent.category)")
        } catch {
            logger.error("Failed to decode realtime event: \(error.localizedDescription)")
        }
    }
}
