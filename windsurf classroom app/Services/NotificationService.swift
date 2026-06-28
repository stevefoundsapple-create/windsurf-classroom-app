//
//  NotificationService.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation
import Combine
import UserNotifications
import SwiftUI
import os.log
import Supabase

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    private let logger = Logger(subsystem: "ClassroomApp", category: "Notifications")
    private let supabaseService = SupabaseService.shared
    
    @Published var isRegistered: Bool = false
    @Published var deviceToken: String?
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    /// Requests APNs permission and registers the device token with Supabase
    func registerForPushNotifications() async {
        do {
            let granted = try await requestAuthorization()
            
            guard granted else {
                logger.info("Push notification permission denied")
                return
            }
            
            // Register for remote notifications on the main thread
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
            logger.info("Push notification registration requested")
        } catch {
            logger.error("Failed to request push notification permission: \(error.localizedDescription)")
        }
    }
    
    /// Requests authorization for alerts, badges, and sounds
    private func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
    }
    
    /// Saves the device token to Supabase for the current user
    func registerDeviceToken(_ token: Data) async {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        
        do {
            let session = try await supabaseService.auth.session
            let userId = session.user.id
            
            try await supabaseService.saveDeviceToken(tokenString, forUserId: userId)
            isRegistered = true
            logger.info("Device token registered successfully")
        } catch {
            logger.error("Failed to register device token: \(error.localizedDescription)")
        }
    }
    
    /// Handles registration failure
    func handleRegistrationFailure(_ error: Error) {
        logger.error("Failed to register for remote notifications: \(error.localizedDescription)")
        isRegistered = false
    }
    
    /// Unregisters the device token when logging out
    func unregisterDeviceToken() async {
        guard let deviceToken = deviceToken else {
            return
        }
        
        do {
            let session = try await supabaseService.auth.session
            let userId = session.user.id
            
            try await supabaseService.deleteDeviceToken(deviceToken, forUserId: userId)
            self.deviceToken = nil
            isRegistered = false
            logger.info("Device token unregistered successfully")
        } catch {
            logger.error("Failed to unregister device token: \(error.localizedDescription)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    /// Called when a notification is delivered while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when the user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let message = response.notification.request.content.body
        
        // Handle deep link to ParentFeedView
        if let studentId = userInfo["student_id"] as? String {
            NotificationCenter.default.post(
                name: .notificationTapped,
                object: nil,
                userInfo: [
                    "student_id": studentId,
                    "message": message
                ]
            )
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let notificationTapped = Notification.Name("notificationTapped")
}
