//
//  LogBehaviorSheet.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import SwiftUI

struct LogBehaviorSheet: View {
    let student: Student
    let teacherId: UUID
    let classId: UUID
    let onOptimisticUpdate: ((UUID, Int) -> Void)?
    @StateObject private var viewModel: LogBehaviorViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(student: Student, teacherId: UUID, classId: UUID, onOptimisticUpdate: ((UUID, Int) -> Void)?) {
        self.student = student
        self.teacherId = teacherId
        self.classId = classId
        self.onOptimisticUpdate = onOptimisticUpdate
        self._viewModel = StateObject(wrappedValue: LogBehaviorViewModel(teacherId: teacherId, classId: classId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        studentHeader
                        
                        behaviorTypeToggle
                        
                        categoryChips
                        
                        noteField
                        
                        if let errorMessage = viewModel.errorMessage {
                            errorView(errorMessage)
                        }
                        
                        submitButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Log Behavior")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(.red)
                    .accessibilityLabel("Cancel")
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .onAppear {
                viewModel.onOptimisticUpdate = onOptimisticUpdate
            }
        }
    }
    
    private var studentHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.8), .blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text(String(student.name.prefix(1)).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .accessibilityLabel("\(student.name) avatar")
            
            VStack(alignment: .leading, spacing: 6) {
                Text(student.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("\(student.pointTotal) points")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Image(systemName: student.pointTotal >= 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(student.pointTotal >= 0 ? .green : .orange)
                
                Text(student.pointTotal >= 0 ? "Good" : "Needs Help")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(student.pointTotal >= 0 ? .green : .orange)
            }
            .accessibilityLabel("Status: \(student.pointTotal >= 0 ? "Good" : "Needs Help")")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    private var behaviorTypeToggle: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Behavior Type")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Step 1 of 3")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 0) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.toggleBehaviorType()
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                        Text("Positive")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(viewModel.isPositive ? Color.green : Color(.systemGray6))
                    )
                    .foregroundColor(viewModel.isPositive ? .white : .primary)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Positive behavior")
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.toggleBehaviorType()
                    }
                }) {
                    HStack {
                        Image(systemName: "minus.circle.fill")
                            .font(.body)
                        Text("Negative")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(!viewModel.isPositive ? Color.red : Color(.systemGray6))
                    )
                    .foregroundColor(!viewModel.isPositive ? .white : .primary)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Negative behavior")
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    private var categoryChips: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Category")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Step 2 of 3")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
            
            if viewModel.isLoadingCategories {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 140), spacing: 12)
                ], spacing: 12) {
                    ForEach(0..<6, id: \.self) { _ in
                        CategorySkeletonChip()
                    }
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 140), spacing: 12)
                ], spacing: 12) {
                    ForEach(viewModel.categories) { category in
                        CategoryChip(
                            category: category,
                            isSelected: viewModel.selectedCategory?.id == category.id,
                            isPositive: viewModel.isPositive
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectCategory(category)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var noteField: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Note")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("(optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            TextField("Add context or details...", text: $viewModel.note, axis: .vertical)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemBackground))
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .lineLimit(3...6)
                .accessibilityLabel("Note")
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.1))
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }

    private func errorView(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.body)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.1))
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }

    private var submitButton: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Confirm")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("Step 3 of 3")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                Task {
                    await viewModel.logEvent(for: student)
                    if viewModel.errorMessage == nil {
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.success)
                        
                        dismiss()
                    } else {
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.error)
                    }
                }
            }) {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                        
                        Text("Log Behavior")
                            .fontWeight(.bold)
                            .font(.body)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: viewModel.canSubmit ? 
                                    (viewModel.isPositive ? [.green, .green.opacity(0.8)] : [.red, .red.opacity(0.8)]) :
                                    [.gray, .gray.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: viewModel.canSubmit ? 
                                (viewModel.isPositive ? .green.opacity(0.3) : .red.opacity(0.3)) : 
                                .clear, 
                               radius: 8, x: 0, y: 4)
                )
                .foregroundColor(.white)
            }
            .disabled(!viewModel.canSubmit)
            .opacity(viewModel.canSubmit ? 1.0 : 0.6)
            .scaleEffect(viewModel.canSubmit ? 1.0 : 0.98)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.canSubmit)
            .accessibilityLabel("Log behavior")
            .accessibilityHint("Submits the behavior event")
        }
    }
}

struct CategorySkeletonChip: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 16)
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
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
        .accessibilityHidden(true)
    }
}

struct CategoryChip: View {
    let category: BehaviorCategory
    let isSelected: Bool
    let isPositive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 8) {
                Text(category.label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: category.points > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.caption2)
                    
                    Text("\(category.points > 0 ? "+" : "")\(category.points)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(isSelected ? (isPositive ? .green : .red) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected ?
                        (isPositive ? Color.green.opacity(0.15) : Color.red.opacity(0.15)) :
                        Color(.systemBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isSelected ?
                                (isPositive ? Color.green : Color.red) :
                                Color(.systemGray4),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isSelected ? 
                            (isPositive ? .green.opacity(0.2) : .red.opacity(0.2)) :
                            .black.opacity(0.05), 
                           radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
            )
            .foregroundColor(
                isSelected ? 
                (isPositive ? Color.green : Color.red) :
                Color.primary
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(category.label), \(category.points) points")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    LogBehaviorSheet(
        student: Student(
            id: UUID(),
            userId: nil,
            name: "John Doe",
            classId: UUID(),
            parentId: UUID(),
            pointTotal: 15
        ),
        teacherId: UUID(),
        classId: UUID(),
        onOptimisticUpdate: { _, _ in }
    )
}
