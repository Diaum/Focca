import Foundation

class SessionSyncManager {
    static let shared = SessionSyncManager()
    
    private let userDefaults = UserDefaults.standard
    private let migrationKey = "historical_data_migrated"
    
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
    
    func migrateHistoricalData() async {
        guard !userDefaults.bool(forKey: migrationKey) else {
            print("ℹ️ [SessionSync] Migração já foi realizada anteriormente")
            return
        }
        
        guard let _ = try? await SupabaseManager.shared.getCurrentSession() else {
            print("⚠️ [SessionSync] Usuário não autenticado, pulando migração")
            return
        }
        
        print("🔄 [SessionSync] Iniciando migração de dados históricos...")
        
        let allDailyTimes = TimerStorage.shared.getAllDailyTimes()
        print("📊 [SessionSync] Encontrados \(allDailyTimes.count) dias com dados históricos")
        
        var successCount = 0
        var errorCount = 0
        var skippedCount = 0
        
        for (date, timeInterval) in allDailyTimes {
            do {
                let durationMinutes = Int(timeInterval / 60)
                
                if durationMinutes <= 0 {
                    skippedCount += 1
                    continue
                }
                
                let exists = try await SupabaseManager.shared.checkSessionExists(date: date)
                
                if exists {
                    skippedCount += 1
                    print("⏭️ [SessionSync] Dados para \(formatDate(date)) já existem no banco, pulando")
                    continue
                }
                
                try await SupabaseManager.shared.syncSession(date: date, durationMinutes: durationMinutes)
                successCount += 1
                print("✅ [SessionSync] Migrado: \(durationMinutes) minutos em \(formatDate(date))")
                
                try await Task.sleep(nanoseconds: 100_000_000)
            } catch {
                errorCount += 1
                print("❌ [SessionSync] Erro ao migrar \(formatDate(date)): \(error.localizedDescription)")
            }
        }
        
        if successCount > 0 || errorCount == 0 {
            userDefaults.set(true, forKey: migrationKey)
            print("✅ [SessionSync] Migração concluída: \(successCount) sucessos, \(skippedCount) pulados, \(errorCount) erros")
        } else {
            print("⚠️ [SessionSync] Migração parcial: \(successCount) sucessos, \(skippedCount) pulados, \(errorCount) erros")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func resetMigrationFlag() {
        userDefaults.removeObject(forKey: migrationKey)
        print("🔄 [SessionSync] Flag de migração resetada")
    }
}

