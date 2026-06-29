import Foundation
import Supabase

protocol AuthServiceProtocol: AnyObject {
    func signIn(email: String, password: String) async throws -> Session
    func signOut() async throws
    func fetchProfile(userId: UUID) async throws -> UserProfile
    func currentSession() async throws -> Session?
    func currentUser() async throws -> User?
}
