//
//  ParentFeedViewModel.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/02.
//

import Foundation
import Combine
import Supabase
import os.log

@MainActor
class ParentFeedViewModel: ObservableObject {
    private let supabaseService: SupabaseServiceProtocol
    private let logger = Logger(subsystem: "ClassroomApp", category: "ParentFeed")
    
    @Published var events: [BehaviorEvent] = []
    @Published var child: Student?
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var newEventIds: Set<UUID> = []
    private var lastOpenedAt: Date?
    
    private var realtimeChannel: RealtimeChannelV2?
    private var realtimeSubscription: RealtimeSubscription?
    
    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }
    
    /// Fetches the child linked to the parent and their behavior events
    func fetchChildAndEvents(parentId: UUID) async {
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
            
            // Fetch events for the child
            let fetchedEvents = try await supabaseService.fetchBehaviorEvents(studentId: child.id, limit: 100)
            events = fetchedEvents
            
            // Track last opened time for highlighting new events
            lastOpenedAt = UserDefaults.standard.object(forKey: "parentFeedLastOpened") as? Date
            UserDefaults.standard.set(Date(), forKey: "parentFeedLastOpened")
            
            // Identify new events since last open
            if let lastOpened = lastOpenedAt {
                newEventIds = Set(fetchedEvents.filter { $0.createdAt > lastOpened }.map { $0.id })
            }
            
        } catch {
            logger.error("Failed to fetch child and events: \(error.localizedDescription)")
            // Provide user-friendly error message without exposing raw Supabase errors
            errorMessage = "Unable to load your child's data. Please check your connection and try again."
        }
        
        isLoading = false
    }
    
    /// Refreshes the child and events data
    func refreshData(parentId: UUID) async {
        await fetchChildAndEvents(parentId: parentId)
    }
    
    /// Subscribes to realtime updates for the child's behavior events
    func subscribeToRealtime(studentId: UUID) {
        logger.info("Subscribing to realtime updates for student: \(studentId)")
        
        let channelName = "parent_\(studentId.uuidString)"
        realtimeChannel = supabaseService.realtime.channel(channelName)
        
        guard let channel = realtimeChannel else {
            logger.error("Failed to create realtime channel")
            return
        }
        
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
            
            logger.info("Realtime unsubscription complete")
        }
    }
    
    /// Handles a new behavior event received from realtime
    private func handleNewEvent(_ record: [String: Any]) {
        logger.info("Received new event from realtime")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: record)
            let newEvent = try JSONDecoder().decode(BehaviorEvent.self, from: jsonData)
            
            events.insert(newEvent, at: 0)
            newEventIds.insert(newEvent.id)
            
            logger.info("Successfully processed new event: \(newEvent.category)")
        } catch {
            logger.error("Failed to decode realtime event: \(error.localizedDescription)")
        }
    }
    
    /// Calculates today's net point total
    var todayPointTotal: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return events
            .filter { calendar.isDate($0.createdAt, inSameDayAs: today) }
            .reduce(0) { $0 + $1.points }
    }
    
    /// Groups events by day for the feed
    var groupedEvents: [(date: Date, events: [BehaviorEvent])] {
        let calendar = Calendar.current
        var groups: [Date: [BehaviorEvent]] = [:]
        
        for event in events {
            let dayStart = calendar.startOfDay(for: event.createdAt)
            groups[dayStart, default: []].append(event)
        }
        
        return groups.sorted { $0.key > $1.key }.map { (date: $0.key, events: $0.value) }
    }
    
    /// Checks if an event is new (received since last app open)
    func isNewEvent(_ event: BehaviorEvent) -> Bool {
        newEventIds.contains(event.id)
    }
}
