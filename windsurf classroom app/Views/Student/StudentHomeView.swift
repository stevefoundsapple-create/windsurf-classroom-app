//
//  StudentHomeView.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import SwiftUI

struct StudentHomeView: View {
    @StateObject private var viewModel = StudentHomeViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Four state handling: Setup, Loading, Error, Empty, Content
                if viewModel.needsSetup {
                    setupView
                        .accessibilityIdentifier("student-setup")
                } else if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else if viewModel.events.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }

            // Confetti overlay for positive events
            if viewModel.showConfetti {
                ConfettiView()
            }
        }
        .navigationTitle("My Points")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        Task {
                            if let userId = authViewModel.currentUser?.id {
                                await viewModel.refreshEvents(userId: userId)
                            }
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh")

                    Button {
                        Task {
                            await authViewModel.logout()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                    .accessibilityLabel("Sign out")
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                }
                .accessibilityLabel("More options")
            }
        }
        .task {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.fetchEvents(userId: userId)
                // Only subscribe to realtime if student record exists
                if !viewModel.needsSetup, let studentId = viewModel.currentStudentId {
                    viewModel.subscribeToRealtime(studentId: studentId)
                }
            }
        }
        .onDisappear {
            viewModel.unsubscribeFromRealtime()
        }
    }
    
    // MARK: - Content Views
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: []) {
                // Point Total Header
                pointTotalCard
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Event Feed
                ForEach(viewModel.events) { event in
                    StudentEventRow(event: event)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
        .accessibilityIdentifier("student-content")
        .refreshable {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.fetchEvents(userId: userId)
            }
        }
    }
    
    private var pointTotalCard: some View {
        VStack(spacing: 16) {
            Text("Your Points")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: viewModel.pointTotal >= 0 ? "star.circle.fill" : "exclamationmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.pointTotal >= 0 ? .green : .orange)
                
                Text("\(viewModel.pointTotal)")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(viewModel.pointTotal >= 0 ? .green : .orange)
                    .minimumScaleFactor(0.5)
            }
            
            Text(viewModel.pointTotal >= 0 ? "Keep up the great work!" : "You can do better!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your points")
        .accessibilityValue("\(viewModel.pointTotal) points")
        .accessibilityIdentifier("student-point-total")
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            // Skeleton Point Card
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
                StudentEventSkeletonRow()
                    .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .accessibilityIdentifier("student-loading")
    }
    
    private var setupView: some View {
        StudentSetupView(
            userId: authViewModel.currentUser?.id ?? UUID(),
            onComplete: {
                if let userId = authViewModel.currentUser?.id {
                    viewModel.setupComplete(userId: userId)
                }
            },
            onSignOut: {
                Task {
                    await authViewModel.logout()
                }
            }
        )
    }
    
    private func errorView(_ message: String) -> some View {
        ErrorStateView(
            title: "Couldn't Load Data",
            message: message,
            retryAction: {
                Task {
                    if let userId = authViewModel.currentUser?.id {
                        await viewModel.refreshEvents(userId: userId)
                    }
                }
            }
        )
        .accessibilityIdentifier("student-error")
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "star.square.fill")
                .font(.system(.largeTitle, design: .default))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green.opacity(0.6), .blue.opacity(0.6)],
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
                
                Text("Your teacher hasn't logged any behavior events yet. Check back soon!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .accessibilityIdentifier("student-empty")
    }
}

// MARK: - Student Event Row

struct StudentEventRow: View {
    let event: BehaviorEvent
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Points Indicator
            ZStack {
                Circle()
                    .fill(event.isPositive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Text("\(event.isPositive ? "+" : "")\(event.points)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(event.isPositive ? .green : .red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Category Label
                Text(event.category)
                    .font(.headline)
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
            
            // Positive/Negative Indicator Icon
            Image(systemName: event.isPositive ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                .font(.title3)
                .foregroundColor(event.isPositive ? .green : .red)
                .opacity(0.6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .accessibilityLabel("\(event.category), \(event.points) points")
        .accessibilityHint("Behavior event at \(timeFormatter.string(from: event.createdAt))")
        .accessibilityIdentifier("student-event-row-\(event.id.uuidString)")
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                Canvas { context, size in
                    for particle in particles {
                        var path = Path()
                        let rect = CGRect(
                            x: particle.x,
                            y: particle.y,
                            width: particle.size,
                            height: particle.size
                        )
                        path.addRect(rect)
                        
                        context.fill(path, with: .color(particle.color))
                    }
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                size: CGFloat.random(in: 8...16),
                color: colors.randomElement() ?? .blue,
                speed: CGFloat.random(in: 3...6),
                wobble: CGFloat.random(in: -2...2)
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        withAnimation(.linear(duration: 2)) {
            for index in particles.indices {
                particles[index].y = size.height + 50
                particles[index].x += particles[index].wobble * 10
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    let speed: CGFloat
    let wobble: CGFloat
}

// MARK: - Student Event Skeleton Row

struct StudentEventSkeletonRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Skeleton indicator
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
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
                    .frame(width: 120, height: 20)
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
        StudentHomeView()
    }
    .environmentObject(AuthViewModel())
}
