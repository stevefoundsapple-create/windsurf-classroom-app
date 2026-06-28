//
//  ParentHomeView.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/03.
//

import SwiftUI

struct ParentHomeView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Feed Tab
            ParentFeedView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Reports Tab
            ParentReportsView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Reports")
                }
                .tag(1)
            
            // Settings Tab
            ParentSettingsView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.purple)
    }
}

#Preview {
    ParentHomeView()
        .environmentObject(AuthViewModel())
}
