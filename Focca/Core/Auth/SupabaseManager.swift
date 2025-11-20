import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    private var client: SupabaseClient?
    
    private init() {
        setupClient()
    }
    
    private func setupClient() {
        let url = URL(string: SupabaseConfig.url)!
        client = SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
    }
    
    func sendOtp(email: String) async throws {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        try await client.auth.signInWithOTP(email: email, redirectTo: nil)
    }
    
    func verifyOtp(email: String, code: String) async throws -> Session {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        let response = try await client.auth.verifyOTP(email: email, token: code, type: .email)
        guard let session = response.session else {
            throw SupabaseError.invalidCredentials
        }
        return session
    }
    
    func getCurrentSession() async throws -> Session? {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        do {
            return try await client.auth.session
        } catch {
            return nil
        }
    }
    
    func signOut() async throws {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        try await client.auth.signOut()
    }
    
    func syncSession(date: Date, durationMinutes: Int) async throws {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        guard let session = try? await client.auth.session else {
            throw SupabaseError.userNotAuthenticated
        }
        
        let userId = session.user.id
        
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: dateOnly)
        
        let exists = try await checkSessionExists(date: date)
        
        struct FocusSession: Encodable {
            let user_id: UUID
            let date: String
            let duration_minutes: Int
        }
        
        let sessionData = FocusSession(
            user_id: userId,
            date: dateString,
            duration_minutes: durationMinutes
        )
        
        if exists {
            try await client.database
                .from("focus_sessions")
                .update(sessionData)
                .eq("user_id", value: userId.uuidString)
                .eq("date", value: dateString)
                .execute()
        } else {
            try await client.database
                .from("focus_sessions")
                .insert(sessionData)
                .execute()
        }
    }
    
    func checkSessionExists(date: Date) async throws -> Bool {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        guard let session = try? await client.auth.session else {
            throw SupabaseError.userNotAuthenticated
        }
        
        let userId = session.user.id
        
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: dateOnly)
        
        let response: [FocusSessionRecord] = try await client.database
            .from("focus_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: dateString)
            .execute()
            .value
        
        return !response.isEmpty
    }
    
    struct FocusSessionRecord: Decodable {
        let id: UUID
        let user_id: UUID
        let date: String
        let duration_minutes: Int
    }
}

enum SupabaseError: LocalizedError {
    case clientNotInitialized
    case userNotAuthenticated
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .clientNotInitialized:
            return "Supabase não foi inicializado corretamente"
        case .userNotAuthenticated:
            return "Usuário não autenticado"
        case .invalidCredentials:
            return "Credenciais inválidas"
        }
    }
}

