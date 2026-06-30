//
//  ParentFeedView.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import SwiftUI

struct ParentFeedView: View {
    @StateObject private var viewModel = ParentFeedViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showingLinkChildSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    } else if viewModel.child == nil {
                        noChildView
                    } else if viewModel.events.isEmpty {
                        emptyStateView
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle("My Child")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            if let parentId = authViewModel.currentUser?.id {
                UserDefaults.standard.set(parentId.uuidString, forKey: "cachedParentId")
                await viewModel.fetchChildAndEvents(parentId: parentId)
                if let child = viewModel.child {
                    viewModel.subscribeToRealtime(studentId: child.id)
                }
            }
        }
        .onDisappear {
            viewModel.unsubscribeFromRealtime()
        }
        .sheet(isPresented: $showingLinkChildSheet) {
            LinkChildView { 
                Task {
                    if let parentId = authViewModel.currentUser?.id {
                        await viewModel.fetchChildAndEvents(parentId: parentId)
                    }
                }
            }
        }
    }
    
    // MARK: - Content Views
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Header Card
                headerCard
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                // Event Feed grouped by day
                ForEach(viewModel.groupedEvents, id: \.date) { dayGroup in
                    Section {
                        ForEach(dayGroup.events) { event in
                            EventRow(
                                event: event,
                                isNew: viewModel.isNewEvent(event)
                            )
                            .padding(.horizontal, 16)
                            .accessibilityIdentifier("parent-event-row-\(event.id.uuidString)")
                        }
                    } header: {
                        DateSeparator(date: dayGroup.date)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            if let parentId = authViewModel.currentUser?.id {
                await viewModel.fetchChildAndEvents(parentId: parentId)
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 20) {
            // Child Avatar and Name
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.8), .pink.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 4)
                    
                    if let child = viewModel.child {
                        Text(String(child.name.prefix(1)).uppercased())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.child?.name ?? "Unknown")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Today's Activity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Today's Point Total
            HStack {
                Spacer()
                
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: viewModel.todayPointTotal >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.title3)
                            .foregroundColor(viewModel.todayPointTotal >= 0 ? .green : .red)
                        
                        Text("\(abs(viewModel.todayPointTotal))")
                            .font(.title.weight(.bold))
                            .foregroundColor(viewModel.todayPointTotal >= 0 ? .green : .red)
                    }
                    
                    Text("points today")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            // Skeleton Header
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 160)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.1),
                                    Color.gray.opacity(0.2),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .clipped()
            
            // Skeleton Event Rows
            ForEach(0..<5, id: \.self) { _ in
                EventSkeletonRow()
                    .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .accessibilityIdentifier("parent-feed-loading")
    }
    
    private func errorView(_ message: String) -> some View {
        ErrorStateView(
            title: "Couldn't Load Data",
            message: message,
            retryAction: {
                Task {
                    if let parentId = authViewModel.currentUser?.id {
                        await viewModel.refreshData(parentId: parentId)
                    }
                }
            }
        )
        .accessibilityIdentifier("parent-feed-error")
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(.largeTitle, design: .default))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.6), .pink.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityLabel("No events")
            
            VStack(spacing: 8) {
                Text("No Events Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("No events logged today yet. Check back later for updates on your child's day!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .accessibilityIdentifier("parent-feed-empty")
    }
    
    private var noChildView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.questionmark.fill")
                .font(.system(.largeTitle, design: .default))
                .foregroundColor(.orange.opacity(0.6))
                .accessibilityLabel("No child linked")
            
            VStack(spacing: 8) {
                Text("No Child Linked")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Your account is not linked to any student. Search for your child to link your account.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Button(action: {
                showingLinkChildSheet = true
            }) {
                HStack {
                    Image(systemName: "link.circle.fill")
                    Text("Link Your Child")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue)
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            .accessibilityLabel("Link your child")
            .accessibilityIdentifier("parent-link-child-button")
            
            Spacer()
        }
        .accessibilityIdentifier("parent-no-child")
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: BehaviorEvent
    let isNew: Bool
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Points Indicator
            ZStack {
                Circle()
                    .fill(event.isPositive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text("\(event.isPositive ? "+" : "")\(event.points)")
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(event.isPositive ? .green : .red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Category Label
                Text(event.category)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Timestamp
                Text(timeFormatter.string(from: event.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Optional Note
                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // New indicator
            if isNew {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isNew ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .accessibilityLabel("\(event.category), \(event.isPositive ? "positive" : "negative"), \(event.points) points at \(timeFormatter.string(from: event.createdAt))")
    }
}

// MARK: - Date Separator

struct DateSeparator: View {
    let date: Date
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            Text(isToday ? "Today" : dateFormatter.string(from: date))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Event Skeleton Row

struct EventSkeletonRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Skeleton indicator
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.1),
                                    Color.gray.opacity(0.3),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: isAnimating ? .leading : .trailing,
                                endPoint: isAnimating ? .trailing : .leading
                            )
                        )
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                )
                .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                // Skeleton category
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.1),
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.1)
                                    ],
                                    startPoint: isAnimating ? .leading : .trailing,
                                    endPoint: isAnimating ? .trailing : .leading
                                )
                            )
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                    )
                    .clipped()
                
                // Skeleton timestamp
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.1),
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.1)
                                    ],
                                    startPoint: isAnimating ? .leading : .trailing,
                                    endPoint: isAnimating ? .trailing : .leading
                                )
                            )
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                    )
                    .clipped()
            }
            
            Spacer()
            
            // Skeleton points
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.1),
                                    Color.gray.opacity(0.3),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: isAnimating ? .leading : .trailing,
                                endPoint: isAnimating ? .trailing : .leading
                            )
                        )
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                )
                .clipped()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ParentFeedView()
            .environmentObject(AuthViewModel())
    }
}
