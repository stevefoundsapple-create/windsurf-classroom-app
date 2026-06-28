//
//  ClassDashboardView.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import SwiftUI

struct ClassDashboardView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: ClassDashboardViewModel
    @State private var showingLogBehavior = false
    @State private var selectedStudentForProfile: Student?
    @State private var showingSettings = false
    @State private var showingAddStudent = false
    @State private var showingClassSetup = false
    @State private var showingClassCode = false
    @State private var createdClassId: UUID?
    
    init() {
        // Initialize with empty classId - will be updated when authViewModel is available
        _viewModel = StateObject(wrappedValue: ClassDashboardViewModel(classId: nil, teacherId: nil))
    }
    
    let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient following iOS 26 design
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with class info
                    headerView
                    
                    // Main content with three state handling: Loading, Error, Empty, Content
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    } else if viewModel.students.isEmpty {
                        emptyStateView
                    } else {
                        studentGridView
                    }
                }
            }
            .navigationTitle("My Classroom")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            if authViewModel.currentUser?.classId != nil || createdClassId != nil {
                                showingAddStudent = true
                            } else {
                                showingClassSetup = true
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            if authViewModel.currentUser?.classId != nil || createdClassId != nil {
                                showingClassCode = true
                            }
                        }) {
                            Image(systemName: "qrcode")
                                .font(.headline)
                                .foregroundColor((authViewModel.currentUser?.classId != nil || createdClassId != nil) ? .blue : .gray.opacity(0.3))
                        }
                        .disabled(authViewModel.currentUser?.classId == nil && createdClassId == nil)
                        
                        Menu {
                            Button(action: viewModel.refreshStudents) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            Button(action: { showingSettings = true }) {
                                Label("Settings", systemImage: "gearshape")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(item: $viewModel.selectedStudent) { student in
                if let teacherId = authViewModel.currentUser?.id, let classId = authViewModel.currentUser?.classId ?? createdClassId {
                    LogBehaviorSheet(
                        student: student,
                        teacherId: teacherId,
                        classId: classId,
                        onOptimisticUpdate: { studentId, newPoints in
                            viewModel.updateStudentPoints(studentId: studentId, newPoints: newPoints)
                        }
                    )
                }
            }
            .sheet(item: $selectedStudentForProfile) { student in
                if let teacherId = authViewModel.currentUser?.id, let classId = authViewModel.currentUser?.classId ?? createdClassId {
                    StudentProfileView(student: student, teacherId: teacherId, classId: classId)
                }
            }
            .sheet(isPresented: $showingSettings) {
                TeacherSettingsView()
            }
            .sheet(isPresented: $showingAddStudent) {
                if let classId = authViewModel.currentUser?.classId ?? createdClassId {
                    AddStudentSheet(classId: classId) {
                        viewModel.refreshStudents()
                    }
                }
            }
            .sheet(isPresented: $showingClassSetup) {
                ClassSetupView { classId in
                    createdClassId = classId
                    viewModel.updateClassId(classId)
                    showingClassSetup = false
                    // Now show add student sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingAddStudent = true
                    }
                } onCancel: {
                    showingClassSetup = false
                }
            }
            .sheet(isPresented: $showingClassCode) {
                if let classCode = viewModel.classCode {
                    ClassCodeSheet(classCode: classCode)
                }
            }
            .refreshable {
                viewModel.refreshStudents()
            }
            .task {
                // Update classId and teacherId from authViewModel when view appears
                viewModel.updateClassId(authViewModel.currentUser?.classId)
                viewModel.updateTeacherId(authViewModel.currentUser?.id)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.students.count) Students")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Tap any student to log behavior")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quick stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.students.reduce(0) { $0 + $1.pointTotal })")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("Total Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var loadingView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonCardView()
                }
            }
            .padding()
        }
    }
    
    private func errorView(_ message: String) -> some View {
        ErrorStateView(
            title: "Couldn't Load Students",
            message: "We had trouble loading your classroom. Please check your connection and try again.",
            retryAction: {
                viewModel.refreshStudents()
            }
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(.largeTitle, design: .default))
                .foregroundColor(.blue.opacity(0.6))
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: true)
            
            VStack(spacing: 8) {
                Text("No Students Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Add students to your classroom to start tracking behavior and building positive habits")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            Button(action: {
                if authViewModel.currentUser?.classId != nil || createdClassId != nil {
                    showingAddStudent = true
                } else {
                    showingClassSetup = true
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Student")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var studentGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.students) { student in
                    StudentCardView(
                        student: student,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectStudent(student)
                            }
                        },
                        onLongPress: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedStudentForProfile = student
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
    }
}

struct ClassCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let classCode: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("Your Class Code")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Share this code with your students to join your classroom")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Class Code Display
                VStack(spacing: 16) {
                    Text(classCode)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                    
                    Button {
                        UIPasteboard.general.string = classCode
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Code")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Done Button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.blue)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Class Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StudentCardView: View {
    let student: Student
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Student Avatar with modern design
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.8), .blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 64, height: 64)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text(String(student.name.prefix(1)).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Student Name
            Text(student.name)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            // Point Total with modern design
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Image(systemName: student.pointTotal >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundColor(student.pointTotal >= 0 ? .green : .red)
                    
                    Text("\(abs(student.pointTotal))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(student.pointTotal >= 0 ? .green : .red)
                }
                
                Text("points")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: student.pointTotal)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(
            minimumDuration: 0.5,
            maximumDistance: 10,
            perform: {
                // Add haptic feedback for long press
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                onLongPress()
            }
        )
        .buttonStyle(PlainButtonStyle())
    }
}

struct SkeletonCardView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Skeleton Avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 64, height: 64)
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
            
            // Skeleton Name
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
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
            
            // Skeleton Points
            VStack(spacing: 4) {
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
                    .frame(width: 30, height: 12)
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
        .frame(maxWidth: .infinity)
        .padding(16)
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
    ClassDashboardView()
}

// Preview helper for StudentCardView
#Preview("Student Card") {
    VStack {
        StudentCardView(
            student: Student(
                id: UUID(),
                userId: nil,
                name: "John Doe",
                classId: UUID(),
                parentId: UUID(),
                pointTotal: 15
            ),
            onTap: { },
            onLongPress: { }
        )

        Spacer()
    }
    .padding()
}
