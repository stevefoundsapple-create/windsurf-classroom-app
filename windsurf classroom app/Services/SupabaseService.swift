//
//  SupabaseService.swift
//  windsurf classroom app
//
//  Created by Max Mokrane on 2026/05/01.
//

import Foundation
import Supabase

class SupabaseService: SupabaseServiceProtocol {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        guard let supabaseURL = URL(string: SupabaseConfig.url) else {
            fatalError("Invalid Supabase URL in configuration")
        }
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
    
    var auth: AuthClient {
        return client.auth
    }
    
    /// Returns the new RealtimeClientV2 instance (RealtimeClient is deprecated)
    var realtime: RealtimeClientV2 {
        return client.realtimeV2
    }
    
    // MARK: - Auth Operations
    
    func signIn(email: String, password: String) async throws -> Session {
        return try await client.auth.signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getCurrentSession() async throws -> Session? {
        return try await client.auth.session
    }
    
    func getCurrentSessionUserId() async throws -> UUID? {
        let session = try await client.auth.session
        return session.user.id
    }
    
    // MARK: - Classes Table Operations
    
    func createClass(_ classObj: Class) async throws {
        try await client
            .from("classes")
            .insert(classObj)
            .execute()
    }
    
    /// Alternative class creation using RPC to bypass RLS issues
    func createClassViaRPC(_ classObj: Class) async throws {
        let params = [
            "p_id": classObj.id.uuidString.lowercased(),
            "p_name": classObj.name,
            "p_teacher_id": classObj.teacherId.uuidString.lowercased(),
            "p_class_code": classObj.classCode
        ]
        
        try await client
            .rpc("create_class_secure", params: params)
            .execute()
    }
    
    func fetchClass(id: UUID) async throws -> Class {
        let classObj: Class = try await client
            .from("classes")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        return classObj
    }
    
    func fetchClassByTeacherId(teacherId: UUID) async throws -> Class? {
        let classes: [Class] = try await client
            .from("classes")
            .select()
            .eq("teacher_id", value: teacherId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return classes.first
    }
    
    func fetchClassByCode(_ code: String) async throws -> Class? {
        let classes: [Class] = try await client
            .from("classes")
            .select()
            .ilike("class_code", pattern: code)
            .limit(1)
            .execute()
            .value
        
        return classes.first
    }
    
    // MARK: - Profiles Table Operations
    
    func fetchProfile(userId: UUID) async throws -> UserProfile {
        let response: UserProfile = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        return response
    }
    
    func createProfile(_ profile: UserProfile) async throws {
        try await client
            .from("profiles")
            .insert(profile)
            .execute()
    }
    
    func updateProfileClassId(userId: UUID, classId: UUID) async throws {
        struct ProfileUpdate: Encodable {
            let class_id: String
        }
        
        let update = ProfileUpdate(class_id: classId.uuidString.lowercased())
        try await client
            .from("profiles")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    // MARK: - Students Table Operations
    
    func fetchStudents(classId: UUID) async throws -> [Student] {
        let students: [Student] = try await client
            .from("students")
            .select()
            .eq("class_id", value: classId.uuidString)
            .order("name")
            .execute()
            .value
        
        return students
    }
    
    func fetchStudent(id: UUID) async throws -> Student {
        let student: Student = try await client
            .from("students")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        return student
    }
    
    func fetchStudentByParentId(parentId: UUID) async throws -> Student? {
        let students: [Student] = try await client
            .from("students")
            .select()
            .eq("parent_id", value: parentId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return students.first
    }
    
    func fetchStudentByUserId(userId: UUID) async throws -> Student? {
        let students: [Student] = try await client
            .from("students")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return students.first
    }
    
    func createStudent(_ student: Student) async throws {
        try await client
            .from("students")
            .insert(student)
            .execute()
    }
    
    /// Alternative student creation using RPC to bypass RLS issues
    func createStudentViaRPC(_ student: Student) async throws {
        struct StudentParams: Encodable {
            let p_id: String
            let p_user_id: String?
            let p_name: String
            let p_class_id: String
            let p_parent_id: String?
            let p_point_total: Int
        }
        
        let params = StudentParams(
            p_id: student.id.uuidString.lowercased(),
            p_user_id: student.userId?.uuidString.lowercased(),
            p_name: student.name,
            p_class_id: student.classId.uuidString.lowercased(),
            p_parent_id: student.parentId?.uuidString.lowercased(),
            p_point_total: student.pointTotal
        )
        
        try await client
            .rpc("create_student_secure", params: params)
            .execute()
    }
    
    func updateStudentPoints(studentId: UUID, newTotal: Int) async throws {
        try await client
            .from("students")
            .update(["point_total": newTotal])
            .eq("id", value: studentId.uuidString)
            .execute()
    }
    
    // MARK: - Behavior Events Table Operations
    
    func logBehaviorEvent(_ event: BehaviorEvent) async throws {
        try await client
            .from("behavior_events")
            .insert(event)
            .execute()
    }
    
    func fetchBehaviorEvents(studentId: UUID, limit: Int = 50) async throws -> [BehaviorEvent] {
        let events: [BehaviorEvent] = try await client
            .from("behavior_events")
            .select()
            .eq("student_id", value: studentId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return events
    }
    
    func fetchBehaviorEventsForClass(classId: UUID, limit: Int = 100) async throws -> [BehaviorEvent] {
        // This would require joining with students table to filter by class_id
        // For now, implementing a basic version
        let events: [BehaviorEvent] = try await client
            .from("behavior_events")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return events
    }
    
    // MARK: - Behavior Categories Table Operations
    
    func fetchBehaviorCategories(classId: UUID) async throws -> [BehaviorCategory] {
        let categories: [BehaviorCategory] = try await client
            .from("behavior_categories")
            .select()
            .eq("class_id", value: classId.uuidString)
            .order("label")
            .execute()
            .value
        
        return categories
    }
    
    func createBehaviorCategory(_ category: BehaviorCategory) async throws {
        try await client
            .from("behavior_categories")
            .insert(category)
            .execute()
    }
    
    func updateBehaviorCategory(_ category: BehaviorCategory) async throws {
        struct CategoryUpdate: Encodable {
            let label: String
            let is_positive: Bool
            let points: Int
        }
        
        let update = CategoryUpdate(
            label: category.label,
            is_positive: category.isPositive,
            points: category.points
        )
        
        try await client
            .from("behavior_categories")
            .update(update)
            .eq("id", value: category.id.uuidString)
            .execute()
    }
    
    func deleteBehaviorCategory(id: UUID) async throws {
        try await client
            .from("behavior_categories")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Device Tokens Table Operations
    
    func saveDeviceToken(_ token: String, forUserId userId: UUID) async throws {
        struct DeviceTokenRecord: Codable {
            let user_id: String
            let token: String
            let platform: String
        }
        
        let record = DeviceTokenRecord(
            user_id: userId.uuidString,
            token: token,
            platform: "ios"
        )
        
        try await client
            .from("device_tokens")
            .upsert(record, onConflict: "user_id, token")
            .execute()
    }
    
    func deleteDeviceToken(_ token: String, forUserId userId: UUID) async throws {
        try await client
            .from("device_tokens")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("token", value: token)
            .execute()
    }
    
    // MARK: - Parent-Child Linking
    
    /// Searches for students by name (case-insensitive partial match)
    func searchStudentsByName(_ name: String) async throws -> [Student] {
        let students: [Student] = try await client
            .from("students")
            .select()
            .ilike("name", pattern: "%\(name)%")
            .limit(10)
            .execute()
            .value
        
        return students
    }
    
    /// Links a parent to a student by setting the parent_id
    func linkParentToStudent(parentId: UUID, studentId: UUID) async throws {
        try await client
            .from("students")
            .update(["parent_id": parentId.uuidString])
            .eq("id", value: studentId.uuidString)
            .execute()
    }
    
    /// Unlinks a parent from a student by setting parent_id to null
    func unlinkParentFromStudent(studentId: UUID) async throws {
        struct ParentUpdate: Encodable {
            let parent_id: String?
        }
        
        let update = ParentUpdate(parent_id: nil)
        try await client
            .from("students")
            .update(update)
            .eq("id", value: studentId.uuidString)
            .execute()
    }
    
    /// Fetches all students linked to a parent
    func fetchStudentsByParentId(parentId: UUID) async throws -> [Student] {
        let students: [Student] = try await client
            .from("students")
            .select()
            .eq("parent_id", value: parentId.uuidString)
            .order("name")
            .execute()
            .value
        
        return students
    }
    
    // MARK: - Push Notification Triggers

    func triggerBehaviorNotification(eventId: UUID, studentId: UUID, category: String, isPositive: Bool, points: Int, note: String?) async throws {
        struct NotificationPayload: Encodable {
            let eventId: String
            let studentId: String
            let category: String
            let isPositive: Bool
            let points: Int
            let note: String?
        }

        let payload = NotificationPayload(
            eventId: eventId.uuidString,
            studentId: studentId.uuidString,
            category: category,
            isPositive: isPositive,
            points: points,
            note: note
        )

        let options = FunctionInvokeOptions(
            body: payload
        )

        try await client.functions.invoke("send-behavior-notification", options: options)
    }

    // MARK: - Account Deletion

    func deleteAccount(userId: UUID) async throws {
        let params = ["p_user_id": userId.uuidString.lowercased()]
        try await client
            .rpc("delete_user_account_secure", params: params)
            .execute()
    }

    // MARK: - Notification Preferences Table Operations
    
    /// Fetches notification preferences for a user
    func fetchNotificationPreferences(userId: UUID) async throws -> NotificationPreferences? {
        let preferences: [NotificationPreferences] = try await client
            .from("notification_preferences")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return preferences.first
    }
    
    /// Creates notification preferences for a user
    func createNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        try await client
            .from("notification_preferences")
            .insert(preferences)
            .execute()
    }
    
    /// Updates notification preferences for a user
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        struct PreferencesUpdate: Encodable {
            let positive_behaviors: Bool
            let negative_behaviors: Bool
            let weekly_summaries: Bool
            let quiet_hours_enabled: Bool
            let quiet_hours_start: String
            let quiet_hours_end: String
        }
        
        let update = PreferencesUpdate(
            positive_behaviors: preferences.positiveBehaviors,
            negative_behaviors: preferences.negativeBehaviors,
            weekly_summaries: preferences.weeklySummaries,
            quiet_hours_enabled: preferences.quietHoursEnabled,
            quiet_hours_start: preferences.quietHoursStart,
            quiet_hours_end: preferences.quietHoursEnd
        )
        
        try await client
            .from("notification_preferences")
            .update(update)
            .eq("user_id", value: preferences.userId.uuidString)
            .execute()
    }
}
