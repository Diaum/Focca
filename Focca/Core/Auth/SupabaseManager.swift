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
        
        let existingRecord = try await fetchSessionRecord(dateString: dateString, userId: userId)
        let existingMinutes = existingRecord?.duration_minutes ?? 0
        let totalMinutes = existingMinutes + durationMinutes
        
        struct FocusSession: Encodable {
            let user_id: UUID
            let date: String
            let duration_minutes: Int
        }
        
        let sessionData = FocusSession(
            user_id: userId,
            date: dateString,
            duration_minutes: totalMinutes
        )
        
        if let record = existingRecord {
            try await client.database
                .from("focus_sessions")
                .update(["duration_minutes": totalMinutes])
                .eq("id", value: record.id.uuidString)
                .execute()
        } else {
            try await client.database
                .from("focus_sessions")
                .insert(sessionData)
                .execute()
        }
    }
    
    private func fetchSessionRecord(dateString: String, userId: UUID) async throws -> FocusSessionRecord? {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        let response: [FocusSessionRecord] = try await client.database
            .from("focus_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: dateString)
            .limit(1)
            .execute()
            .value
        
        return response.first
    }
    
    struct FocusSessionRecord: Decodable {
        let id: UUID
        let user_id: UUID
        let date: String
        let duration_minutes: Int
    }

    struct UserAwardRecord: Decodable {
        let id: UUID
        let user_id: UUID
        let award_id: String
        let unlocked_at: Date?
    }
    
    func getSessions(from startDate: Date? = nil, to endDate: Date? = nil) async throws -> [FocusSessionRecord] {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        guard let session = try? await client.auth.session else {
            throw SupabaseError.userNotAuthenticated
        }
        
        let userId = session.user.id
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // Busca todas as sessões do usuário
        var allSessions: [FocusSessionRecord] = try await client.database
            .from("focus_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .execute()
            .value
        
        // Filtra por data no Swift se necessário
        if let startDate = startDate {
            let startString = formatter.string(from: startDate)
            allSessions = allSessions.filter { $0.date >= startString }
        }
        
        if let endDate = endDate {
            let endString = formatter.string(from: endDate)
            allSessions = allSessions.filter { $0.date <= endString }
        }
        
        return allSessions
    }

    func fetchAwards() async throws -> [String] {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        guard let session = try? await client.auth.session else {
            throw SupabaseError.userNotAuthenticated
        }
        
        let userId = session.user.id
        
        let records: [UserAwardRecord] = try await client.database
            .from("user_awards")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("unlocked_at", ascending: true)
            .execute()
            .value
        
        return records.map { $0.award_id }
    }
    
    func saveAward(_ awardId: String) async throws {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        guard let session = try? await client.auth.session else {
            throw SupabaseError.userNotAuthenticated
        }
        
        let userId = session.user.id
        
        let existing: [UserAwardRecord] = try await client.database
            .from("user_awards")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("award_id", value: awardId)
            .execute()
            .value
        
        guard existing.isEmpty else { return }
        
        struct InsertAward: Encodable {
            let user_id: UUID
            let award_id: String
        }
        
        let record = InsertAward(user_id: userId, award_id: awardId)
        
        try await client.database
            .from("user_awards")
            .insert(record)
            .execute()
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

