//
//  ParentReportsView.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/03.
//

import SwiftUI

struct ParentReportsView: View {
    @StateObject private var viewModel = ParentReportsViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    
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
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            if let parentId = authViewModel.currentUser?.id {
                await viewModel.fetchReports(parentId: parentId)
            }
        }
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Weekly Summary Card
                weeklySummaryCard
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Trend Charts
                trendSection
                    .padding(.horizontal, 16)
                
                // Recent Reports
                recentReportsSection
                    .padding(.horizontal, 16)
                
                Spacer(minLength: 20)
            }
        }
        .refreshable {
            if let parentId = authViewModel.currentUser?.id {
                await viewModel.refreshReports(parentId: parentId)
            }
        }
    }
    
    private var weeklySummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(viewModel.weeklyStartDate) - \(viewModel.weeklyEndDate)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.weeklyPointTotal)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.weeklyPointTotal >= 0 ? .green : .red)
                    
                    Text("total points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack(spacing: 0) {
                // Positive Events
                VStack(spacing: 4) {
                    Text("\(viewModel.weeklyPositiveEvents)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Positive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                
                // Negative Events
                VStack(spacing: 4) {
                    Text("\(viewModel.weeklyNegativeEvents)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("Needs Work")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trends")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Simple trend visualization
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(viewModel.weeklyTrend) { dayData in
                    trendBar(for: dayData)
                }
            }
            .frame(height: 100)
            .padding(.horizontal, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    private func trendBar(for dayData: DayTrend) -> some View {
        let barColor = dayData.points >= 0 ? Color.green.opacity(0.7) : Color.red.opacity(0.7)
        let barHeight = CGFloat(abs(dayData.points)) * 4 + 4
        let dayLabel = String(dayData.day.prefix(3))
        
        return VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(barColor)
                .frame(width: 24, height: barHeight)
            
            Text(dayLabel)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var recentReportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous Weeks")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            ForEach(viewModel.previousWeeks, id: \.id) { week in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(week.dateRange)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("\(week.positiveEvents) positive, \(week.negativeEvents) needs work")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(week.totalPoints)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(week.totalPoints >= 0 ? .green : .red)
                }
                .padding(.vertical, 8)
                
                if week.id != viewModel.previousWeeks.last?.id {
                    Divider()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { _ in
                ReportSkeletonCard()
                    .padding(.horizontal, 16)
            }
            Spacer()
        }
    }
    
    private func errorView(_ message: String) -> some View {
        ErrorStateView(
            title: "Couldn't Load Reports",
            message: message,
            retryAction: {
                Task {
                    if let parentId = authViewModel.currentUser?.id {
                        await viewModel.refreshReports(parentId: parentId)
                    }
                }
            }
        )
    }
    
    private var noChildView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.questionmark.fill")
                .font(.system(.largeTitle, design: .default))
                .foregroundColor(.orange.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Child Linked")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Your account is not linked to any student. Please contact your child's teacher.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

// MARK: - Report Skeleton Card

struct ReportSkeletonCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 20)
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
                        .frame(width: 80, height: 14)
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
                
                VStack(alignment: .trailing, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 24)
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
                        .frame(width: 60, height: 12)
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
            }
            
            Divider()
            
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 30, height: 24)
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
                        .frame(width: 40, height: 12)
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
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 30, height: 24)
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
                        .frame(width: 40, height: 12)
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
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ParentReportsView()
        .environmentObject(AuthViewModel())
}
