import Foundation
import FamilyControls
import ManagedSettings

/// Rastreia o tempo de bloqueio por app individual
class AppBlockingTracker {
    static let shared = AppBlockingTracker()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
    
    private init() {}
    
    // MARK: - Modelos
    
    struct AppBlockingSession: Codable {
        let appTokenHash: Int
        let startDate: Date
        var endDate: Date?
        var duration: TimeInterval {
            let end = endDate ?? Date()
            return end.timeIntervalSince(startDate)
        }
    }
    
    struct DailyAppBlocking: Codable {
        let date: Date
        var sessions: [AppBlockingSession]
        
        var totalTimeByApp: [Int: TimeInterval] {
            var result: [Int: TimeInterval] = [:]
            for session in sessions {
                result[session.appTokenHash, default: 0] += session.duration
            }
            return result
        }
    }
    
    // MARK: - Registrar Bloqueio
    
    /// Registra o início de um bloqueio para uma lista de apps
    /// Aceita FamilyActivitySelection e extrai os tokens internamente
    func startBlocking(selection: FamilyActivitySelection, startDate: Date = Date()) {
        let apps = Array(selection.applicationTokens)
        startBlocking(appHashes: apps.map { $0.hashValue }, startDate: startDate)
    }
    
    /// Versão interna que trabalha apenas com hashes
    private func startBlocking(appHashes: [Int], startDate: Date) {
        let dateKey = formatDate(startDate)
        var dailyBlocking = loadDailyBlocking(for: dateKey) ?? DailyAppBlocking(
            date: Calendar.current.startOfDay(for: startDate),
            sessions: []
        )
        
        // Finaliza todas as sessões ativas (endDate == nil) antes de criar novas
        // Isso garante que não haja sessões duplicadas ou órfãs
        for index in dailyBlocking.sessions.indices {
            if dailyBlocking.sessions[index].endDate == nil {
                dailyBlocking.sessions[index] = AppBlockingSession(
                    appTokenHash: dailyBlocking.sessions[index].appTokenHash,
                    startDate: dailyBlocking.sessions[index].startDate,
                    endDate: startDate // Finaliza no momento do novo bloqueio
                )
            }
        }
        
        // Cria uma nova sessão para cada app
        for hash in appHashes {
            let session = AppBlockingSession(
                appTokenHash: hash,
                startDate: startDate,
                endDate: nil
            )
            dailyBlocking.sessions.append(session)
        }
        
        saveDailyBlocking(dailyBlocking, for: dateKey)
        print("📱 [AppBlockingTracker] Iniciado bloqueio para \(appHashes.count) apps")
    }
    
    /// Finaliza o bloqueio para uma lista de apps
    /// Aceita FamilyActivitySelection e extrai os tokens internamente
    func endBlocking(selection: FamilyActivitySelection, endDate: Date = Date()) {
        let apps = Array(selection.applicationTokens)
        endBlocking(appHashes: apps.map { $0.hashValue }, endDate: endDate)
    }
    
    /// Versão interna que trabalha apenas com hashes
    private func endBlocking(appHashes: [Int], endDate: Date) {
        let dateKey = formatDate(endDate)
        guard var dailyBlocking = loadDailyBlocking(for: dateKey) else {
            print("⚠️ [AppBlockingTracker] Nenhum bloqueio encontrado para finalizar")
            return
        }
        
        // Finaliza sessões ativas para os apps fornecidos
        for hash in appHashes {
            // Encontra a última sessão ativa para este app
            if let index = dailyBlocking.sessions.lastIndex(where: { 
                $0.appTokenHash == hash && $0.endDate == nil 
            }) {
                dailyBlocking.sessions[index] = AppBlockingSession(
                    appTokenHash: hash,
                    startDate: dailyBlocking.sessions[index].startDate,
                    endDate: endDate
                )
            }
        }
        
        saveDailyBlocking(dailyBlocking, for: dateKey)
        print("📱 [AppBlockingTracker] Finalizado bloqueio para \(appHashes.count) apps")
    }
    
    // MARK: - Consultar Dados
    
    /// Retorna o tempo total bloqueado por app em uma data específica
    func getAppBlockingTimes(for date: Date) -> [Int: TimeInterval] {
        let dateKey = formatDate(date)
        guard let dailyBlocking = loadDailyBlocking(for: dateKey) else {
            return [:]
        }
        
        return dailyBlocking.totalTimeByApp
    }
    
    /// Retorna informações detalhadas dos apps bloqueados em uma data
    func getAppBlockingDetails(for date: Date) -> [(appTokenHash: Int, time: TimeInterval)] {
        let times = getAppBlockingTimes(for: date)
        return times.map { (appTokenHash: $0.key, time: $0.value) }
            .sorted { $0.time > $1.time }
    }
    
    /// Retorna o tempo total bloqueado de um app específico em uma data
    func getBlockingTime(for appTokenHash: Int, on date: Date) -> TimeInterval {
        let times = getAppBlockingTimes(for: date)
        return times[appTokenHash] ?? 0
    }
    
    /// Retorna o tempo total bloqueado de um app em todas as datas
    func getTotalBlockingTime(for appTokenHash: Int) -> TimeInterval {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let blockingKeys = allKeys.filter { $0.hasPrefix("app_blocking_") }
        
        var total: TimeInterval = 0
        for key in blockingKeys {
            if let data = userDefaults.data(forKey: key),
               let dailyBlocking = try? JSONDecoder().decode(DailyAppBlocking.self, from: data) {
                let times = dailyBlocking.totalTimeByApp
                total += times[appTokenHash] ?? 0
            }
        }
        
        return total
    }
    
    // MARK: - Resetar Dados
    
    /// Reseta todos os dados de bloqueio de apps
    func resetAllBlockingData() {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let blockingKeys = allKeys.filter { $0.hasPrefix("app_blocking_") }
        
        for key in blockingKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        print("🗑️ [AppBlockingTracker] Todos os dados de bloqueio foram resetados")
    }
    
    /// Reseta os dados de bloqueio de uma data específica
    func resetBlockingData(for date: Date) {
        let dateKey = formatDate(date)
        let key = "app_blocking_\(dateKey)"
        userDefaults.removeObject(forKey: key)
        print("🗑️ [AppBlockingTracker] Dados de bloqueio resetados para \(dateKey)")
    }
    
    /// Reseta apenas as sessões ativas (endDate == nil) de uma data específica
    func resetActiveSessions(for date: Date) {
        let dateKey = formatDate(date)
        guard var dailyBlocking = loadDailyBlocking(for: dateKey) else {
            return
        }
        
        // Remove todas as sessões ativas
        dailyBlocking.sessions = dailyBlocking.sessions.filter { $0.endDate != nil }
        
        saveDailyBlocking(dailyBlocking, for: dateKey)
        print("🗑️ [AppBlockingTracker] Sessões ativas resetadas para \(dateKey)")
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func loadDailyBlocking(for dateKey: String) -> DailyAppBlocking? {
        let key = "app_blocking_\(dateKey)"
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(DailyAppBlocking.self, from: data)
    }
    
    private func saveDailyBlocking(_ blocking: DailyAppBlocking, for dateKey: String) {
        let key = "app_blocking_\(dateKey)"
        if let encoded = try? JSONEncoder().encode(blocking) {
            userDefaults.set(encoded, forKey: key)
        }
    }
}

