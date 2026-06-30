//
//  StudentProfileView.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import SwiftUI

struct StudentProfileView: View {
    let student: Student
    let teacherId: UUID
    let classId: UUID
    @StateObject private var viewModel: StudentProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(student: Student, teacherId: UUID, classId: UUID) {
        self.student = student
        self.teacherId = teacherId
        self.classId = classId
        self._viewModel = StateObject(wrappedValue: StudentProfileViewModel(student: student))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        studentHeaderCard
                        
                        statsOverview
                        
                        filterButtons
                        
                        eventsFeed
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Student Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .accessibilityLabel("Done")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.refreshEvents) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                    }
                    .accessibilityLabel("Refresh events")
                }
            }
            .refreshable {
                viewModel.refreshEvents()
            }
            .sheet(isPresented: $viewModel.showingLogBehavior) {
                LogBehaviorSheet(
                    student: student,
                    teacherId: teacherId,
                    classId: classId,
                    onOptimisticUpdate: { _, _ in
                        viewModel.refreshEvents()
                    }
                )
            }
        }
    }
    
    private var studentHeaderCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.8), .blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    Text(String(student.name.prefix(1)).uppercased())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(student.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(student.pointTotal)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(student.pointTotal >= 0 ? .green : .red)
                            
                            Text("Total Points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Image(systemName: student.pointTotal >= 0 ? "star.fill" : "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundColor(student.pointTotal >= 0 ? .yellow : .orange)
                            
                            Text(student.pointTotal >= 0 ? "Excellent" : "Needs Support")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(student.pointTotal >= 0 ? .yellow : .orange)
                        }
                    }
                }
                
                Spacer()
            }
            
            Button(action: viewModel.showLogBehaviorSheet) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                    
                    Text("Log Behavior")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Log behavior")
            .accessibilityHint("Opens the behavior logging form")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        )
    }
    
    private var statsOverview: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Positive",
                value: viewModel.totalPositiveEvents,
                color: .green,
                icon: "arrow.up.circle.fill"
            )
            
            StatCard(
                title: "Negative",
                value: viewModel.totalNegativeEvents,
                color: .red,
                icon: "arrow.down.circle.fill"
            )
            
            StatCard(
                title: "Net",
                value: viewModel.netPointsThisPeriod,
                color: viewModel.netPointsThisPeriod >= 0 ? .green : .red,
                icon: viewModel.netPointsThisPeriod >= 0 ? "plus.circle.fill" : "minus.circle.fill"
            )
        }
    }
    
    private var filterButtons: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Behavior History")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(viewModel.events.count) events")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 12) {
                ForEach(FeedFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.setFilter(filter)
                        }
                    }) {
                        Text(filter.localizedDisplayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(viewModel.filter == filter ? Color.blue : Color(.systemGray6))
                            )
                            .foregroundColor(viewModel.filter == filter ? .white : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Filter: \(filter.localizedDisplayName)")
                }
                
                Spacer()
            }
        }
    }
    
    private var eventsFeed: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                loadingSkeletonView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else if viewModel.events.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.events) { event in
                        BehaviorEventFeedItem(event: event)
                    }
                }
            }
        }
    }
    
    private var loadingSkeletonView: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                BehaviorEventSkeletonItem()
            }
        }
        .padding(.vertical, 8)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(.orange.opacity(0.7))
                .accessibilityLabel("Error")
            
            VStack(spacing: 8) {
                Text("Couldn't Load Events")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("We had trouble loading the behavior history. Please check your connection and try again.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)
            }
            
            Button(action: viewModel.refreshEvents) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 8)
            .accessibilityLabel("Try again")
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.6))
                .accessibilityLabel("No events")
            
            Text("No behavior events")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("No behavior has been logged for this student in the selected time period.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(.vertical, 40)
    }
}

struct StatCard: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Text("\(abs(value))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue("\(value)")
    }
}

struct BehaviorEventSkeletonItem: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
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

struct BehaviorEventFeedItem: View {
    let event: BehaviorEvent
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private var accessibilityDescription: String {
        let time = dateFormatter.string(from: event.createdAt)
        return "\(event.category), \(event.points) points at \(time)"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(event.isPositive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: event.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.body)
                    .foregroundColor(event.isPositive ? .green : .red)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.category)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(event.points > 0 ? "+" : "")
                        Text("\(event.points)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(event.isPositive ? .green : .red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill((event.isPositive ? Color.green : Color.red).opacity(0.1))
                    )
                }
                
                if let note = event.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(dateFormatter.string(from: event.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .accessibilityLabel(accessibilityDescription)
    }
}

#Preview {
    StudentProfileView(
        student: Student(
            id: UUID(),
            userId: nil,
            name: "John Doe",
            classId: UUID(),
            parentId: UUID(),
            pointTotal: 15
        ),
        teacherId: UUID(),
        classId: UUID()
    )
}
