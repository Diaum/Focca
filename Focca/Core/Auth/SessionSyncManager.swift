import Foundation

class SessionSyncManager {
    static let shared = SessionSyncManager()
    
    private init() {}
    
    func syncSession(date: Date, duration: TimeInterval) {
        Task {
            do {
                let durationMinutes = Int(duration / 60)
                try await SupabaseManager.shared.syncSession(date: date, durationMinutes: durationMinutes)
                print("✅ [SessionSync] Sessão sincronizada: \(durationMinutes) minutos em \(date)")
            } catch {
                print("❌ [SessionSync] Erro ao sincronizar sessão: \(error.localizedDescription)")
            }
        }
    }
}

