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
        
        // Calcula a duração até uma data específica (útil para consultas históricas)
        func duration(until date: Date) -> TimeInterval {
            if let end = endDate {
                // Sessão já finalizada, usa o endDate salvo
                return end.timeIntervalSince(startDate)
            } else {
                // Sessão ainda ativa, calcula até a data fornecida
                return date.timeIntervalSince(startDate)
            }
        }
    }
    
    struct DailyAppBlocking: Codable {
        let date: Date
        var sessions: [AppBlockingSession]
        
        var totalTimeByApp: [Int: TimeInterval] {
            var result: [Int: TimeInterval] = [:]
            let now = Date()
            var ignoredCount = 0
            var ignoredHashes = Set<Int>()
            
            for session in sessions {
                // Para sessões ativas, calcula até agora
                // Para sessões finalizadas, usa o endDate salvo
                let duration: TimeInterval
                if let endDate = session.endDate {
                    // Sessão finalizada: usa o endDate salvo
                    duration = endDate.timeIntervalSince(session.startDate)
                } else {
                    // Sessão ativa: calcula até agora
                    duration = now.timeIntervalSince(session.startDate)
                }
                
                // CRÍTICO: Ignora sessões com duração muito pequena (< 5 segundos)
                // Isso previne contar sessões que foram criadas e finalizadas muito rapidamente
                // (por exemplo, quando o app reinicia e cria sessões desnecessárias)
                if duration >= 5.0 {
                    result[session.appTokenHash, default: 0] += duration
                } else {
                    ignoredCount += 1
                    ignoredHashes.insert(session.appTokenHash)
                }
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
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDay = calendar.startOfDay(for: startDate)
        
        // Se o bloqueio começou em um dia anterior e ainda está ativo, divide entre os dias
        if startDay < today {
            splitOvernightSessions(from: startDay, to: today)
        }
        
        let dateKey = formatDate(Date())
        var dailyBlocking = loadDailyBlocking(for: dateKey) ?? DailyAppBlocking(
            date: today,
            sessions: []
        )
        
        let activeHashes = Set(dailyBlocking.sessions.filter { $0.endDate == nil }.map { $0.appTokenHash })
        let newHashes = Set(appHashes)
        
        let finalizedSessions = dailyBlocking.sessions.filter { $0.endDate != nil }
        
        if activeHashes == newHashes && !activeHashes.isEmpty {
            saveDailyBlocking(dailyBlocking, for: dateKey)
            return
        }
        
        let hashesToRemove = activeHashes.subtracting(newHashes)
        var updatedSessions: [AppBlockingSession] = finalizedSessions
        
        for session in dailyBlocking.sessions {
            if session.endDate == nil {
                let hash = session.appTokenHash
                if hashesToRemove.contains(hash) {
                    updatedSessions.append(AppBlockingSession(
                        appTokenHash: hash,
                        startDate: session.startDate,
                        endDate: Date()
                    ))
                } else if newHashes.contains(hash) {
                    updatedSessions.append(session)
                }
            }
        }
        
        for hash in newHashes {
            let hasActiveSession = updatedSessions.contains { 
                $0.appTokenHash == hash && $0.endDate == nil 
            }
            
            if !hasActiveSession {
                // Se o bloqueio começou em um dia anterior, a sessão do dia atual começa à meia-noite
                let sessionStartDate = startDay < today ? today : startDate
                let session = AppBlockingSession(
                    appTokenHash: hash,
                    startDate: sessionStartDate,
                    endDate: nil
                )
                updatedSessions.append(session)
            }
        }
        
        dailyBlocking.sessions = updatedSessions
        saveDailyBlocking(dailyBlocking, for: dateKey)
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
            return
        }
        
        for hash in appHashes {
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
    }
    
    /// Finaliza TODAS as sessões ativas de uma data específica
    /// Usado quando desbloqueamos para garantir que nenhuma sessão ativa continue contando
    func endAllActiveSessions(for date: Date, endDate: Date = Date()) {
        let dateKey = formatDate(date)
        guard var dailyBlocking = loadDailyBlocking(for: dateKey) else {
            return
        }
        
        var hasChanges = false
        for index in dailyBlocking.sessions.indices {
            if dailyBlocking.sessions[index].endDate == nil {
                dailyBlocking.sessions[index] = AppBlockingSession(
                    appTokenHash: dailyBlocking.sessions[index].appTokenHash,
                    startDate: dailyBlocking.sessions[index].startDate,
                    endDate: endDate
                )
                hasChanges = true
            }
        }
        
        if hasChanges {
            saveDailyBlocking(dailyBlocking, for: dateKey)
        }
    }
    
    /// Retorna o tempo total bloqueado em uma data específica
    /// IMPORTANTE: Calcula o tempo de bloqueio geral (união de todos os períodos de bloqueio),
    /// não a soma dos tempos de cada app individualmente.
    /// Se múltiplos apps estão bloqueados ao mesmo tempo, conta apenas uma vez.
    func getTotalBlockingTime(for date: Date) -> TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateDay = calendar.startOfDay(for: date)
        
        // Se estamos consultando o dia atual e há sessões ativas do dia anterior, divide-as
        if dateDay == today {
            // Verifica se há sessões ativas do dia anterior que precisam ser divididas
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let yesterdayKey = formatDate(yesterday)
            if let yesterdayBlocking = loadDailyBlocking(for: yesterdayKey) {
                let hasActiveSessions = yesterdayBlocking.sessions.contains { $0.endDate == nil }
                if hasActiveSessions {
                    splitOvernightSessions(from: yesterday, to: today)
                }
            }
        }
        
        let dateKey = formatDate(date)
        guard let dailyBlocking = loadDailyBlocking(for: dateKey) else {
            return 0
        }
        
        // Calcula o tempo total baseado na união de todos os períodos de bloqueio
        // Isso garante que se múltiplos apps estão bloqueados ao mesmo tempo,
        // o tempo total seja o período de bloqueio geral, não a soma dos tempos individuais
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let now = Date()
        
        // Verifica se há bloqueio ativo quando consultando o dia atual
        let isCurrentlyBlocked: Bool
        if dateDay == today {
            let sharedDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
            let standardDefaults = UserDefaults.standard
            isCurrentlyBlocked = (sharedDefaults.object(forKey: "blocked_start_date") != nil) ||
                                 (standardDefaults.object(forKey: "blocked_start_date") != nil) ||
                                 standardDefaults.bool(forKey: "blocked_by_schedule")
        } else {
            isCurrentlyBlocked = false
        }
        
        // Cria uma lista de intervalos de bloqueio (start, end) para todas as sessões
        var blockingIntervals: [(start: Date, end: Date)] = []
        
        for session in dailyBlocking.sessions {
            // Ignora sessões muito curtas (< 5 segundos)
            let sessionStart = session.startDate
            // Se a sessão está ativa (sem endDate), só conta se realmente há bloqueio ativo
            let sessionEnd: Date
            if session.endDate == nil {
                if isCurrentlyBlocked {
                    sessionEnd = now
                } else {
                    // Se não há bloqueio ativo, não conta sessões ativas
                    continue
                }
            } else {
                sessionEnd = session.endDate!
            }
            
            // Ajusta para o início e fim do dia
            let adjustedStart = max(sessionStart, dayStart)
            let adjustedEnd = min(sessionEnd, dayEnd)
            
            // Só adiciona se a sessão tem duração válida e está dentro do dia
            if adjustedEnd > adjustedStart {
                let duration = adjustedEnd.timeIntervalSince(adjustedStart)
                if duration >= 5.0 {
                    blockingIntervals.append((start: adjustedStart, end: adjustedEnd))
                }
            }
        }
        
        // Se não há intervalos, retorna 0
        guard !blockingIntervals.isEmpty else {
            return 0
        }
        
        // Ordena os intervalos por data de início
        blockingIntervals.sort { $0.start < $1.start }
        
        // Calcula a união de todos os intervalos (merge de intervalos sobrepostos)
        var mergedIntervals: [(start: Date, end: Date)] = []
        var currentInterval = blockingIntervals[0]
        
        for i in 1..<blockingIntervals.count {
            let nextInterval = blockingIntervals[i]
            
            // Se o próximo intervalo se sobrepõe ou é adjacente ao atual, merge
            if nextInterval.start <= currentInterval.end {
                // Merge: estende o intervalo atual até o fim do próximo
                currentInterval = (
                    start: currentInterval.start,
                    end: max(currentInterval.end, nextInterval.end)
                )
            } else {
                // Não se sobrepõe: adiciona o intervalo atual e começa um novo
                mergedIntervals.append(currentInterval)
                currentInterval = nextInterval
            }
        }
        
        // Adiciona o último intervalo
        mergedIntervals.append(currentInterval)
        
        // Calcula o tempo total somando a duração de todos os intervalos mesclados
        let totalTime = mergedIntervals.reduce(0.0) { total, interval in
            total + interval.end.timeIntervalSince(interval.start)
        }
        
        return totalTime
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
        let dateKey = formatDate(date)
        guard let dailyBlocking = loadDailyBlocking(for: dateKey) else {
            return []
        }
        
        // Calcula o tempo total por app
        let times = dailyBlocking.totalTimeByApp
        
        let details = times.map { (appTokenHash: $0.key, time: $0.value) }
            .sorted { $0.time > $1.time }
        
        return details
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
    
    /// Remove sessões inválidas (duração < 5 segundos) de uma data específica
    func cleanupInvalidSessions(for date: Date) {
        let dateKey = formatDate(date)
        guard var dailyBlocking = loadDailyBlocking(for: dateKey) else {
            return
        }
        
        let originalCount = dailyBlocking.sessions.count
        let now = Date()
        
        // Remove sessões com duração muito pequena
        dailyBlocking.sessions = dailyBlocking.sessions.filter { session in
            let duration: TimeInterval
            if let endDate = session.endDate {
                duration = endDate.timeIntervalSince(session.startDate)
            } else {
                duration = now.timeIntervalSince(session.startDate)
            }
            return duration >= 5.0
        }
        
        let removedCount = originalCount - dailyBlocking.sessions.count
        if removedCount > 0 {
            saveDailyBlocking(dailyBlocking, for: dateKey)
        }
    }
    
    // MARK: - Resetar Dados
    
    /// Reseta todos os dados de bloqueio de apps
    func resetAllBlockingData() {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let blockingKeys = allKeys.filter { $0.hasPrefix("app_blocking_") }
        
        for key in blockingKeys {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    func resetBlockingData(for date: Date) {
        let dateKey = formatDate(date)
        let key = "app_blocking_\(dateKey)"
        userDefaults.removeObject(forKey: key)
    }
    
    func resetActiveSessions(for date: Date) {
        let dateKey = formatDate(date)
        guard var dailyBlocking = loadDailyBlocking(for: dateKey) else {
            return
        }
        
        dailyBlocking.sessions = dailyBlocking.sessions.filter { $0.endDate != nil }
        saveDailyBlocking(dailyBlocking, for: dateKey)
    }
    
    // MARK: - Helpers
    
    /// Divide sessões que atravessam a meia-noite entre os dias
    /// Pode ser chamada publicamente para garantir que sessões sejam divididas corretamente
    func splitOvernightSessions(from startDay: Date, to endDay: Date) {
        let calendar = Calendar.current
        var currentDay = startDay
        
        while currentDay < endDay {
            let dateKey = formatDate(currentDay)
            guard var dailyBlocking = loadDailyBlocking(for: dateKey) else {
                currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
                continue
            }
            
            let nextDayStart = calendar.date(byAdding: .day, value: 1, to: currentDay)!
            var updatedSessions: [AppBlockingSession] = []
            var sessionsToCarryOver: [AppBlockingSession] = []
            
            for session in dailyBlocking.sessions {
                if session.endDate == nil {
                    // Sessão ativa que atravessa a meia-noite
                    // Finaliza no fim do dia atual
                    updatedSessions.append(AppBlockingSession(
                        appTokenHash: session.appTokenHash,
                        startDate: session.startDate,
                        endDate: nextDayStart
                    ))
                    
                    // Cria uma nova sessão para o próximo dia
                    sessionsToCarryOver.append(AppBlockingSession(
                        appTokenHash: session.appTokenHash,
                        startDate: nextDayStart,
                        endDate: nil
                    ))
                } else {
                    // Sessão já finalizada, mantém como está
                    updatedSessions.append(session)
                }
            }
            
            // Salva as sessões atualizadas do dia atual
            dailyBlocking.sessions = updatedSessions
            saveDailyBlocking(dailyBlocking, for: dateKey)
            
            // Salva as sessões para o próximo dia
            if !sessionsToCarryOver.isEmpty {
                let nextDateKey = formatDate(nextDayStart)
                var nextDailyBlocking = loadDailyBlocking(for: nextDateKey) ?? DailyAppBlocking(
                    date: nextDayStart,
                    sessions: []
                )
                
                // Adiciona as sessões do próximo dia, evitando duplicatas
                for session in sessionsToCarryOver {
                    let hasExisting = nextDailyBlocking.sessions.contains { 
                        $0.appTokenHash == session.appTokenHash && $0.endDate == nil 
                    }
                    if !hasExisting {
                        nextDailyBlocking.sessions.append(session)
                    }
                }
                
                saveDailyBlocking(nextDailyBlocking, for: nextDateKey)
            }
            
            currentDay = nextDayStart
        }
    }
    
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
        if let blocking = try? JSONDecoder().decode(DailyAppBlocking.self, from: data) {
            return blocking
        } else {
            return nil
        }
    }
    
    private func saveDailyBlocking(_ blocking: DailyAppBlocking, for dateKey: String) {
        let key = "app_blocking_\(dateKey)"
        if let encoded = try? JSONEncoder().encode(blocking) {
            userDefaults.set(encoded, forKey: key)
            userDefaults.synchronize()
        }
    }
}

