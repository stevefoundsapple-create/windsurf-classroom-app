//
//  ParentSettingsViewModel.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/03.
//

import Foundation
import Combine
import os.log

@MainActor
class ParentSettingsViewModel: ObservableObject {
    private let supabaseService = SupabaseService.shared
    private let logger = Logger(subsystem: "ClassroomApp", category: "ParentSettings")
    
    @Published var children: [Student] = []
    @Published var notificationPreferences: NotificationPreferences?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    /// Fetches all children linked to the parent
    func fetchChildren(parentId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            children = try await supabaseService.fetchStudentsByParentId(parentId: parentId)
            
            if children.isEmpty {
                logger.warning("No children found for parent: \(parentId)")
            }
            
        } catch {
            logger.error("Failed to fetch children: \(error.localizedDescription)")
            errorMessage = "Unable to load child information. Please check your connection and try again."
        }
        
        isLoading = false
    }
    
    /// Fetches notification preferences for the user
    func fetchNotificationPreferences(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            var preferences = try await supabaseService.fetchNotificationPreferences(userId: userId)
            
            // If no preferences exist, create default ones
            if preferences == nil {
                let defaultPreferences = NotificationPreferences(userId: userId)
                try await supabaseService.createNotificationPreferences(defaultPreferences)
                preferences = defaultPreferences
            }
            
            notificationPreferences = preferences
            
        } catch {
            logger.error("Failed to fetch notification preferences: \(error.localizedDescription)")
            errorMessage = "Unable to load notification preferences. Please check your connection and try again."
        }
        
        isLoading = false
    }
    
    /// Updates notification preferences
    func updateNotificationPreferences() async {
        guard let preferences = notificationPreferences else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.updateNotificationPreferences(preferences)
            logger.info("Notification preferences updated successfully")
        } catch {
            logger.error("Failed to update notification preferences: \(error.localizedDescription)")
            errorMessage = "Unable to save notification preferences. Please try again."
        }
        
        isLoading = false
    }
    
    /// Unlinks a child from the parent
    func unlinkChild(_ child: Student) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.unlinkParentFromStudent(studentId: child.id)
            children.removeAll { $0.id == child.id }
            logger.info("Successfully unlinked child: \(child.name)")
        } catch {
            logger.error("Failed to unlink child: \(error.localizedDescription)")
            errorMessage = "Unable to unlink child. Please try again."
        }
        
        isLoading = false
    }
    
    /// Updates a specific notification preference
    func updatePreference(_ keyPath: WritableKeyPath<NotificationPreferences, Bool>, value: Bool) async {
        guard var preferences = notificationPreferences else { return }
        preferences[keyPath: keyPath] = value
        notificationPreferences = preferences
        await updateNotificationPreferences()
    }
}
