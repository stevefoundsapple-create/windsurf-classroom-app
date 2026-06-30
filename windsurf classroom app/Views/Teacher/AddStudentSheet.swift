//
//  AddStudentSheet.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import SwiftUI

struct AddStudentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let classId: UUID
    let onStudentAdded: () -> Void
    
    @StateObject private var viewModel: AddStudentViewModel
    
    init(classId: UUID, onStudentAdded: @escaping () -> Void) {
        self.classId = classId
        self.onStudentAdded = onStudentAdded
        self._viewModel = StateObject(wrappedValue: AddStudentViewModel(classId: classId))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Student Name", text: $viewModel.studentName)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Student name")
                } header: {
                    Text("Student Information")
                } footer: {
                    Text("Enter the student's full name as it will appear in the classroom.")
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let success = await viewModel.addStudent()
                            if success {
                                onStudentAdded()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                    .accessibilityLabel("Add student")
                    .accessibilityHint("Adds the student to the classroom")
                }
            }
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .accessibilityLabel("Adding student")
                }
            }
        }
    }
}

#Preview {
    AddStudentSheet(classId: UUID(), onStudentAdded: {})
}
