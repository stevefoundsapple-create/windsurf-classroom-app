//
//  AppRouter.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import SwiftUI
import Combine

struct AppRouter: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showNotificationAlert = false
    @State private var notificationMessage = ""
    
    var body: some View {
        NavigationStack {
            Group {
                switch authViewModel.currentUser?.role {
                case .teacher:
                    teacherView
                case .parent:
                    parentView
                case .student:
                    studentView
                case .none:
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .notificationTapped)) { notification in
                handleNotificationTap(notification)
            }
            .alert("New Behavior Event", isPresented: $showNotificationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(notificationMessage)
            }
        }
    }
    
    private func handleNotificationTap(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        if authViewModel.currentUser?.role == .parent,
           let message = userInfo["message"] as? String {
            notificationMessage = message
            showNotificationAlert = true
        }
    }
    
    private var teacherView: some View {
        ClassDashboardView()
            .environmentObject(authViewModel)
    }
    
    private var parentView: some View {
        ParentHomeView()
            .environmentObject(authViewModel)
    }
    
    private var studentView: some View {
        StudentHomeView()
            .environmentObject(authViewModel)
    }
}
