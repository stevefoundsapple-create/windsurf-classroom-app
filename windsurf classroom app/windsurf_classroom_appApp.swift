//
//  windsurf_classroom_appApp.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import SwiftUI

@main
struct WindsurfClassroomApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(authViewModel)
        }
    }
}