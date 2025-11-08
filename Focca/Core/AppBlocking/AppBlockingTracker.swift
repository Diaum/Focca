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
        let dateKey = formatDate(startDate)
        var dailyBlocking = loadDailyBlocking(for: dateKey) ?? DailyAppBlocking(
            date: Calendar.current.startOfDay(for: startDate),
            sessions: []
        )
        
        print("📱 [AppBlockingTracker] startBlocking chamado para \(appHashes.count) apps na data \(dateKey)")
        print("   - Sessões existentes (TODAS): \(dailyBlocking.sessions.count)")
        print("   - Sessões ativas: \(dailyBlocking.sessions.filter { $0.endDate == nil }.count)")
        print("   - Sessões finalizadas: \(dailyBlocking.sessions.filter { $0.endDate != nil }.count)")
        
        // Verifica quais apps já têm sessões ativas
        let activeHashes = Set(dailyBlocking.sessions.filter { $0.endDate == nil }.map { $0.appTokenHash })
        let newHashes = Set(appHashes)
        
        // CRÍTICO: Preserva TODAS as sessões finalizadas ANTES de fazer qualquer alteração
        // Isso garante que os dados históricos nunca sejam perdidos
        let finalizedSessions = dailyBlocking.sessions.filter { $0.endDate != nil }
        let finalizedHashes = Set(finalizedSessions.map { $0.appTokenHash })
        
        print("   - Apps com sessões ativas: \(activeHashes)")
        print("   - Novos apps para bloquear: \(newHashes)")
        print("   - Preservando \(finalizedSessions.count) sessões finalizadas (CRÍTICO)")
        print("   - Apps com sessões finalizadas: \(finalizedHashes.count)")
        
        // CRÍTICO: Se os mesmos apps já estão bloqueados (sessões ativas), NÃO faz NADA
        if activeHashes == newHashes && !activeHashes.isEmpty {
            print("📱 [AppBlockingTracker] ✅ Bloqueio já está ativo para estes apps, PRESERVANDO todas as sessões")
            print("   - Sessões ativas: \(activeHashes.count) apps")
            print("   - Total de sessões preservadas: \(dailyBlocking.sessions.count)")
            saveDailyBlocking(dailyBlocking, for: dateKey)
            return
        }
        
        // CRÍTICO: Se não há sessões ativas mas há sessões finalizadas para TODOS os apps solicitados,
        // preserva tudo e NÃO cria novas sessões (isso previne resetar o tempo quando o app reinicia)
        if activeHashes.isEmpty && !finalizedHashes.isEmpty {
            if finalizedHashes.isSuperset(of: newHashes) {
                print("📱 [AppBlockingTracker] ✅ TODOS os apps já têm sessões finalizadas hoje, PRESERVANDO histórico")
                print("   - Apps com sessões finalizadas: \(finalizedHashes.count)")
                print("   - Novos apps solicitados: \(newHashes.count)")
                print("   - Total de sessões preservadas: \(dailyBlocking.sessions.count)")
                saveDailyBlocking(dailyBlocking, for: dateKey)
                return
            }
        }
        
        // Se há sessões ativas mas os apps mudaram, apenas atualiza (não reseta tudo)
        if !activeHashes.isEmpty && activeHashes != newHashes {
            print("📱 [AppBlockingTracker] Apps mudaram, atualizando sessões (mantendo histórico)")
        }
        
        // Finaliza apenas as sessões ativas de apps que não estão mais na nova lista
        let hashesToRemove = activeHashes.subtracting(newHashes)
        var updatedSessions: [AppBlockingSession] = finalizedSessions // SEMPRE começa com sessões finalizadas
        
        // Processa sessões ativas existentes
        for session in dailyBlocking.sessions {
            if session.endDate == nil {
                let hash = session.appTokenHash
                if hashesToRemove.contains(hash) {
                    // Finaliza sessão de app que não está mais na lista
                    // CRÍTICO: Usa Date() em vez de startDate para evitar criar sessões com duração muito pequena
                    updatedSessions.append(AppBlockingSession(
                        appTokenHash: hash,
                        startDate: session.startDate,
                        endDate: Date()
                    ))
                    print("   - Finalizando sessão ativa para hash \(hash)")
                } else if newHashes.contains(hash) {
                    // Mantém sessão ativa se o app ainda está na lista
                    updatedSessions.append(session)
                    print("   - Mantendo sessão ativa para hash \(hash)")
                }
            }
        }
        
        // CRÍTICO: Cria uma nova sessão APENAS para apps que:
        // 1. Não têm sessão ativa
        // 2. Não têm sessão finalizada hoje
        // 3. Estão na lista de novos apps solicitados
        for hash in newHashes {
            let hasActiveSession = updatedSessions.contains { 
                $0.appTokenHash == hash && $0.endDate == nil 
            }
            
            // CRÍTICO: Se já existe uma sessão finalizada para este app hoje, NÃO cria nova sessão
            let hasFinalizedSessionToday = finalizedHashes.contains(hash)
            
            if !hasActiveSession && !hasFinalizedSessionToday {
                // Apenas cria nova sessão se não há sessão ativa E não há sessão finalizada
                let session = AppBlockingSession(
                    appTokenHash: hash,
                    startDate: startDate,
                    endDate: nil
                )
                updatedSessions.append(session)
                print("   - ✅ Criando nova sessão ativa para hash \(hash)")
            } else if hasFinalizedSessionToday {
                print("   - ⚠️ Hash \(hash) já tem sessão finalizada hoje, NÃO criando nova sessão (preservando histórico)")
            } else if hasActiveSession {
                print("   - ℹ️ Hash \(hash) já tem sessão ativa, mantendo existente")
            }
        }
        
        // CRÍTICO: Atualiza o dailyBlocking com todas as sessões preservadas
        dailyBlocking.sessions = updatedSessions
        
        print("📱 [AppBlockingTracker] ✅ Bloqueio atualizado:")
        print("   - Total de sessões: \(dailyBlocking.sessions.count)")
        print("   - Sessões finalizadas preservadas: \(dailyBlocking.sessions.filter { $0.endDate != nil }.count)")
        print("   - Sessões ativas: \(dailyBlocking.sessions.filter { $0.endDate == nil }.count)")
        
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
    
    /// Retorna o tempo total bloqueado em uma data específica
    /// IMPORTANTE: Calcula o tempo de bloqueio geral (união de todos os períodos de bloqueio),
    /// não a soma dos tempos de cada app individualmente.
    /// Se múltiplos apps estão bloqueados ao mesmo tempo, conta apenas uma vez.
    func getTotalBlockingTime(for date: Date) -> TimeInterval {
        let dateKey = formatDate(date)
        guard let dailyBlocking = loadDailyBlocking(for: dateKey) else {
            return 0
        }
        
        // Calcula o tempo total baseado na união de todos os períodos de bloqueio
        // Isso garante que se múltiplos apps estão bloqueados ao mesmo tempo,
        // o tempo total seja o período de bloqueio geral, não a soma dos tempos individuais
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let now = Date()
        
        // Cria uma lista de intervalos de bloqueio (start, end) para todas as sessões
        var blockingIntervals: [(start: Date, end: Date)] = []
        
        for session in dailyBlocking.sessions {
            // Ignora sessões muito curtas (< 5 segundos)
            let sessionStart = session.startDate
            let sessionEnd = session.endDate ?? now
            
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
            print("🧹 [AppBlockingTracker] Removidas \(removedCount) sessões inválidas de \(dateKey)")
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
        if let blocking = try? JSONDecoder().decode(DailyAppBlocking.self, from: data) {
            return blocking
        } else {
            print("❌ [AppBlockingTracker] Erro ao decodificar dados para \(dateKey)")
            return nil
        }
    }
    
    private func saveDailyBlocking(_ blocking: DailyAppBlocking, for dateKey: String) {
        let key = "app_blocking_\(dateKey)"
        if let encoded = try? JSONEncoder().encode(blocking) {
            userDefaults.set(encoded, forKey: key)
            // Força sincronização para garantir persistência
            userDefaults.synchronize()
        } else {
            print("❌ [AppBlockingTracker] Erro ao codificar dados para \(dateKey)")
        }
    }
}

