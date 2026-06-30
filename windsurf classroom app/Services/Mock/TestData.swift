import Foundation
import Supabase

enum MockError: Error {
    case unexpectedCall
}

enum TestData {
    static func makeSession(userId: UUID = UUID()) -> Session {
        Session(
            providerToken: nil,
            providerRefreshToken: nil,
            accessToken: "mock_access_token",
            tokenType: "bearer",
            expiresIn: 3600,
            expiresAt: Date().timeIntervalSince1970 + 3600,
            refreshToken: "mock_refresh_token",
            weakPassword: nil,
            user: User(
                id: userId,
                appMetadata: [:],
                userMetadata: [:],
                aud: "authenticated",
                confirmationSentAt: nil,
                recoverySentAt: nil,
                emailChangeSentAt: nil,
                newEmail: nil,
                invitedAt: nil,
                actionLink: nil,
                email: "test@example.com",
                phone: nil,
                createdAt: Date(),
                confirmedAt: Date(),
                emailConfirmedAt: Date(),
                phoneConfirmedAt: nil,
                lastSignInAt: Date(),
                role: nil,
                updatedAt: Date(),
                identities: nil,
                isAnonymous: false,
                factors: nil
            )
        )
    }

    static func makeTeacherProfile(userId: UUID = UUID()) -> UserProfile {
        UserProfile(id: userId, name: "Test Teacher", email: "teacher@example.com", role: .teacher, classId: UUID())
    }

    static func makeParentProfile(userId: UUID = UUID()) -> UserProfile {
        UserProfile(id: userId, name: "Test Parent", email: "parent@example.com", role: .parent, classId: nil)
    }

    static func makeStudentProfile(userId: UUID = UUID()) -> UserProfile {
        UserProfile(id: userId, name: "Test Student", email: "student@example.com", role: .student, classId: UUID())
    }

    static func makeStudent(id: UUID = UUID(), userId: UUID? = nil, name: String = "Alice", classId: UUID = UUID(), pointTotal: Int = 42) -> Student {
        Student(id: id, userId: userId, name: name, classId: classId, parentId: nil, pointTotal: pointTotal)
    }

    static func makeStudentWithUserId(classId: UUID = UUID()) -> Student {
        Student(id: UUID(), userId: UUID(), name: "Alice", classId: classId, parentId: nil, pointTotal: 42)
    }

    static func makeStudents() -> [Student] {
        let classId = UUID()
        return [
            Student(id: UUID(), userId: UUID(), name: "Alice", classId: classId, parentId: nil, pointTotal: 42),
            Student(id: UUID(), userId: UUID(), name: "Bob", classId: classId, parentId: nil, pointTotal: 28),
            Student(id: UUID(), userId: UUID(), name: "Charlie", classId: classId, parentId: nil, pointTotal: 15),
        ]
    }

    static func makeClass(classId: UUID = UUID()) -> Class {
        Class(id: classId, teacherId: UUID(), name: "Test Class", classCode: "ABC123")
    }

    static func makeBehaviorEvents(studentId: UUID = UUID()) -> [BehaviorEvent] {
        [
            BehaviorEvent(
                id: UUID(),
                studentId: studentId,
                teacherId: UUID(),
                category: "Participated",
                isPositive: true,
                points: 2,
                note: nil,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            BehaviorEvent(
                id: UUID(),
                studentId: studentId,
                teacherId: UUID(),
                category: "Excellent Work",
                isPositive: true,
                points: 5,
                note: "Great job on the assignment!",
                createdAt: Date().addingTimeInterval(-7200)
            ),
            BehaviorEvent(
                id: UUID(),
                studentId: studentId,
                teacherId: UUID(),
                category: "Off-task",
                isPositive: false,
                points: -2,
                note: nil,
                createdAt: Date().addingTimeInterval(-86400)
            ),
        ]
    }

    static func makeCategories() -> [BehaviorCategory] {
        BehaviorCategory.defaultPositiveCategories + BehaviorCategory.defaultNegativeCategories
    }
}
