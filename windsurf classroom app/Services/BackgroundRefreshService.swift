import Foundation
import BackgroundTasks
import UserNotifications
import Supabase
import os.log

final class MutableBox<T>: @unchecked Sendable {
    var value: T?
    init() {}
}

actor BackgroundRefreshService {
    static let shared = BackgroundRefreshService()
    
    static let taskIdentifier = "app.windsurf-classroom-app.behavior-refresh"
    
    private let logger = Logger(subsystem: "ClassroomApp", category: "BackgroundRefresh")
    private let supabaseService: SupabaseServiceProtocol
    
    private init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
    }
    
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
            ) { task in
                Task {
                    await self.handleAppRefresh(task: task as! BGAppRefreshTask)
                }
            }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Background refresh scheduled")
        } catch {
            logger.error("Failed to schedule background refresh: \(error.localizedDescription)")
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        logger.info("Background refresh started")
        
        let parentIdKey = "cachedParentId"
        
        task.expirationHandler = {
            Task { await self.logger.info("Background refresh expired") }
        }
        
        Task {
            let success = await performHybridRefresh(parentIdKey: parentIdKey)
            task.setTaskCompleted(success: success)
            await Self.shared.scheduleAppRefresh()
        }
    }
    
    private func performHybridRefresh(parentIdKey: String) async -> Bool {
        guard let parentIdString = UserDefaults.standard.string(forKey: parentIdKey),
              let parentId = UUID(uuidString: parentIdString) else {
            logger.warning("No cached parent ID — skipping background refresh")
            return true
        }
        
        do {
            guard let child = try await supabaseService.fetchStudentByParentId(parentId: parentId) else {
                logger.warning("No child found for parent in background refresh")
                return true
            }
            
            let lastFetch = UserDefaults.standard.object(forKey: "lastBackgroundFetchDate") as? Date ?? Date.distantPast
            
            // Phase 1: Try realtime — listen for inserts for up to 20 seconds
            if let liveEvent = await listenForRealtimeEvent(childId: child.id, timeoutSeconds: 20) {
                logger.info("Realtime delivered event in background: \(liveEvent.category)")
                try await sendLocalNotification(for: child, events: [liveEvent])
                UserDefaults.standard.set(Date(), forKey: "lastBackgroundFetchDate")
                return true
            }
            
            // Phase 2: Fallback — query DB for events missed before the BGTask started
            let events = try await supabaseService.fetchBehaviorEvents(studentId: child.id, limit: 50)
            let newEvents = events.filter { $0.createdAt > lastFetch }
            
            guard !newEvents.isEmpty else {
                logger.info("No new events since last background fetch")
                return true
            }
            
            try await sendLocalNotification(for: child, events: newEvents)
            UserDefaults.standard.set(Date(), forKey: "lastBackgroundFetchDate")
            return true
            
        } catch {
            logger.error("Background refresh query failed: \(error.localizedDescription)")
            return false
        }
    }
    
    private func listenForRealtimeEvent(childId: UUID, timeoutSeconds: Int) async -> BehaviorEvent? {
        let channelName = "bg_\(childId.uuidString)"
        let channel = supabaseService.realtime.channel(channelName)
        let filter = "student_id=eq.\(childId.uuidString)"
        
        let box = MutableBox<BehaviorEvent>()
        
        let subscription = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "behavior_events",
            filter: filter
        ) { action in
            guard box.value == nil else { return }
            if let data = try? JSONSerialization.data(withJSONObject: action.record),
               let event = try? JSONDecoder().decode(BehaviorEvent.self, from: data) {
                box.value = event
            }
        }
        
        defer {
            subscription.cancel()
            Task { await channel.unsubscribe() }
        }
        
        do {
            try await channel.subscribeWithError()
            
            let deadline = Date.now.addingTimeInterval(TimeInterval(timeoutSeconds))
            while Date.now < deadline && box.value == nil {
                try await Task.sleep(for: .milliseconds(100))
            }
        } catch {
            logger.error("Realtime subscribe failed in background: \(error.localizedDescription)")
        }
        
        return box.value
    }
    
    private func sendLocalNotification(for child: Student, events: [BehaviorEvent]) async throws {
        let positiveCount = events.filter { $0.isPositive }.count
        let negativeCount = events.filter { !$0.isPositive }.count
        
        let content = UNMutableNotificationContent()
        content.title = "\(child.name)'s Behavior Update"
        
        if positiveCount > 0 && negativeCount > 0 {
            content.body = "\(positiveCount) positive and \(negativeCount) negative event\(negativeCount == 1 ? "" : "s")"
        } else if positiveCount > 0 {
            let totalPoints = events.filter { $0.isPositive }.reduce(0) { $0 + $1.points }
            content.body = "\(positiveCount) positive event\(positiveCount == 1 ? "" : "s") · \(totalPoints) points earned"
        } else {
            content.body = "\(negativeCount) negative event\(negativeCount == 1 ? "" : "s")"
        }
        
        if let latestEvent = events.first {
            content.userInfo = [
                "student_id": child.id.uuidString,
                "message": content.body
            ]
            
            if let note = latestEvent.note, !note.isEmpty {
                content.body = "\(latestEvent.category): \(note)"
            } else {
                content.body = "\(latestEvent.category) — \(content.body)"
            }
        }
        
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "bg-refresh-\(child.id.uuidString)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try await UNUserNotificationCenter.current().add(request)
        logger.info("Background notification sent for \(events.count) new events")
    }
}
