import Foundation

class TimerStorage {
    static let shared = TimerStorage()

    private let userDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
    private var cachedSessions: [String: Int] = [:]
    private var lastFetchDate: Date?
    private let cacheValidityInterval: TimeInterval = 300 // 5 minutos
    private let cachedSessionsKey = "cached_focus_sessions"
    private let lastFetchDateKey = "last_fetch_date"
    private let syncedLocalPrefix = "synced_local_seconds_"

    private init() {}
    
    func initializeFirstLaunch() {
        if userDefaults.object(forKey: "first_launch_date") == nil {
            let today = Calendar.current.startOfDay(for: Date())
            userDefaults.set(today, forKey: "first_launch_date")
        }
        cleanOldLocalData()
        loadCachedSessions()
    }
    
    private func loadCachedSessions() {
        if let data = userDefaults.data(forKey: cachedSessionsKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            cachedSessions = decoded
        }
        
        if let lastFetch = userDefaults.object(forKey: lastFetchDateKey) as? Date {
            lastFetchDate = lastFetch
        }
    }
    
    private func saveCachedSessions() {
        if let encoded = try? JSONEncoder().encode(cachedSessions) {
            userDefaults.set(encoded, forKey: cachedSessionsKey)
            userDefaults.set(Date(), forKey: lastFetchDateKey)
            userDefaults.synchronize()
        }
    }
    
    func getDailyTime(for date: Date) -> TimeInterval {
        let dateKey = formatDate(date)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        let daysDifference = calendar.dateComponents([.day], from: targetDate, to: today).day ?? 0
        
        var remoteTime: TimeInterval = 0
        if let cachedMinutes = cachedSessions[dateKey] {
            remoteTime = TimeInterval(cachedMinutes * 60)
        }
        
        var localTime: TimeInterval = 0
        if daysDifference <= 7 {
            localTime = AppBlockingTracker.shared.getTotalBlockingTime(for: date)
        }
        
        let syncedLocal = getSyncedLocalSeconds(for: dateKey)
        let additionalLocal = max(0, localTime - syncedLocal)
        let combinedTime = remoteTime + additionalLocal
        
        if combinedTime > 0 {
            return max(combinedTime, localTime)
        }
        
        // Para datas antigas (>7 dias), busca do banco de dados
        if daysDifference > 7 {
            if let cachedMinutes = cachedSessions[dateKey] {
                return TimeInterval(cachedMinutes * 60)
            }
            
            // Tenta buscar do banco (síncrono para não bloquear UI)
            Task {
                await fetchSessionsFromDatabase()
            }
            
            // Retorna 0 enquanto busca (será atualizado na próxima chamada)
            return 0
        }
        
        // Fallback para dados antigos de daily_time_ (apenas últimos 7 dias)
        let oldTime = userDefaults.double(forKey: "daily_time_\(dateKey)")
        if oldTime > 0 {
            return oldTime
        }
        
        return 0
    }
    
    private func fetchSessionsFromDatabase() async {
        // Evita buscar muito frequentemente
        if let lastFetch = lastFetchDate,
           Date().timeIntervalSince(lastFetch) < cacheValidityInterval {
            return
        }
        
        do {
            let sessions = try await SupabaseManager.shared.getSessions()
            await MainActor.run {
                cachedSessions.removeAll()
                for session in sessions {
                    upsertCachedSession(session)
                }
                lastFetchDate = Date()
            }
        } catch {
            print("⚠️ [TimerStorage] Erro ao buscar sessões do banco: \(error.localizedDescription)")
        }
    }
    
    private func cleanOldLocalData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        // Remove dados de app_blocking_ antigos (>7 dias)
        for key in allKeys where key.hasPrefix("app_blocking_") {
            let dateString = key.replacingOccurrences(of: "app_blocking_", with: "")
            if let date = parseDate(dateString),
               date < sevenDaysAgo {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        // Remove dados de daily_time_ antigos (>7 dias)
        for key in allKeys where key.hasPrefix("daily_time_") {
            let dateString = key.replacingOccurrences(of: "daily_time_", with: "")
            if let date = parseDate(dateString),
               date < sevenDaysAgo {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        userDefaults.synchronize()
    }
    
    func addDailyTime(_ timeInterval: TimeInterval, for date: Date) {
        let dateKey = formatDate(date)
        
        // CRÍTICO: Se o AppBlockingTracker já tem dados para esta data,
        // NÃO adiciona tempo ao daily_time_ para evitar duplicação.
        // O AppBlockingTracker é a fonte principal de verdade.
        let appBlockingTime = AppBlockingTracker.shared.getTotalBlockingTime(for: date)
        if appBlockingTime > 0 {
            print("⚠️ [TimerStorage] AppBlockingTracker já tem dados para \(dateKey), ignorando addDailyTime para evitar duplicação")
            return
        }
        
        // Só adiciona ao daily_time_ se o AppBlockingTracker não tem dados (fallback para dados antigos)
        let currentTime = userDefaults.double(forKey: "daily_time_\(dateKey)")
        let newTime = currentTime + timeInterval
        userDefaults.set(newTime, forKey: "daily_time_\(dateKey)")
    }
    
    func getTodayTime() -> TimeInterval {
        return getDailyTime(for: Date())
    }
    
    func splitOvernightTime(from startDate: Date, to endDate: Date) {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        
        if startDay < endDay {
            let startDayEnd = calendar.date(byAdding: .day, value: 1, to: startDay)!
            let timeInStartDay = startDayEnd.timeIntervalSince(startDate)
            let timeInEndDay = endDate.timeIntervalSince(endDay)
            
            addDailyTime(timeInStartDay, for: startDate)
            addDailyTime(timeInEndDay, for: endDate)
        } else {
            let totalTime = endDate.timeIntervalSince(startDate)
            addDailyTime(totalTime, for: startDate)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func getAllDailyTimes() async -> [(date: Date, time: TimeInterval)] {
        // Primeiro retorna dados do cache (instantâneo)
        let cachedResult = getCachedDailyTimes()
        
        // Em paralelo, busca do banco e atualiza cache
        Task {
            await fetchAndUpdateFromDatabase()
        }
        
        return cachedResult
    }
    
    func getAllDailyTimesWithRefresh() async -> [(date: Date, time: TimeInterval)] {
        // Força atualização do banco
        await fetchAndUpdateFromDatabase()
        return getCachedDailyTimes()
    }
    
    private func getCachedDailyTimes() -> [(date: Date, time: TimeInterval)] {
        var result: [(date: Date, time: TimeInterval)] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        // Primeiro: busca dados locais dos últimos 7 dias (mais recentes)
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let blockingKeys = allKeys.filter { $0.hasPrefix("app_blocking_") }
        var processedDates = Set<String>()
        
        for key in blockingKeys {
            let dateString = key.replacingOccurrences(of: "app_blocking_", with: "")
            
            if processedDates.contains(dateString) {
                continue
            }
            processedDates.insert(dateString)
            
            if let date = parseDate(dateString), date >= sevenDaysAgo {
                let totalTime = AppBlockingTracker.shared.getTotalBlockingTime(for: date)
                if totalTime > 0 {
                    result.append((date: date, time: totalTime))
                }
            }
        }
        
        // Segundo: adiciona dados do cache do banco (histórico)
        for (dateString, minutes) in cachedSessions {
            if let date = parseDate(dateString) {
                // Evita duplicatas com dados locais
                if !result.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                    let time = TimeInterval(minutes * 60)
                    result.append((date: date, time: time))
                }
            }
        }
        
        // Terceiro: busca dados antigos de daily_time_ (apenas últimos 7 dias)
        let timeKeys = allKeys.filter { $0.hasPrefix("daily_time_") }
        for key in timeKeys {
            let time = userDefaults.double(forKey: key)
            if time > 0 {
                let dateString = key.replacingOccurrences(of: "daily_time_", with: "")
                if let date = parseDate(dateString), date >= sevenDaysAgo {
                    if let existingIndex = result.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                        if time > result[existingIndex].time {
                            result[existingIndex] = (date: result[existingIndex].date, time: time)
                        }
                    } else {
                        result.append((date: date, time: time))
                    }
                }
            }
        }
        
        result.sort { $0.date > $1.date }
        return result
    }
    
    private func fetchAndUpdateFromDatabase() async {
        // Evita buscar muito frequentemente
        if let lastFetch = lastFetchDate,
           Date().timeIntervalSince(lastFetch) < cacheValidityInterval {
            return
        }
        
        await fetchAndCacheFromDatabase()
    }
    
    func fetchAndCacheFromDatabase() async {
        do {
            let sessions = try await SupabaseManager.shared.getSessions()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            
            await MainActor.run {
                // Atualiza cache completo
                cachedSessions.removeAll()
                for session in sessions {
                    upsertCachedSession(session)
                }
                lastFetchDate = Date()
                saveCachedSessions()
                print("✅ [TimerStorage] Cache atualizado com \(sessions.count) sessões do banco")
                
                // Salva os últimos 7 dias localmente para cache rápido
                for session in sessions {
                    if let date = parseDate(session.date), date >= sevenDaysAgo {
                        let timeInterval = TimeInterval(session.duration_minutes * 60)
                        // Só salva se não existir dado local mais recente
                        let existingTime = AppBlockingTracker.shared.getTotalBlockingTime(for: date)
                        if existingTime == 0 {
                            // Salva como daily_time_ para compatibilidade
                            let dateKey = formatDate(date)
                            userDefaults.set(timeInterval, forKey: "daily_time_\(dateKey)")
                        }
                    }
                }
                userDefaults.synchronize()
                print("✅ [TimerStorage] Últimos 7 dias salvos localmente para cache")
            }
        } catch {
            print("⚠️ [TimerStorage] Erro ao buscar do banco: \(error.localizedDescription)")
        }
    }
    
    func hasLocalCache() -> Bool {
        // Verifica se há dados locais ou cache do banco
        let hasLocalData = !userDefaults.dictionaryRepresentation().keys.filter { 
            $0.hasPrefix("app_blocking_") || $0.hasPrefix("daily_time_") 
        }.isEmpty
        
        let hasCachedSessions = !cachedSessions.isEmpty
        
        return hasLocalData || hasCachedSessions
    }
    
    func updateCacheForDate(date: Date, durationMinutes: Int) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        await MainActor.run {
            let existingMinutes = cachedSessions[dateString] ?? 0
            cachedSessions[dateString] = existingMinutes + durationMinutes
            saveCachedSessions()
            
            let localTime = AppBlockingTracker.shared.getTotalBlockingTime(for: date)
            setSyncedLocalSeconds(localTime, for: dateString)
        }
    }
    
    func getAllDailyTimesSync() -> [(date: Date, time: TimeInterval)] {
        // Versão síncrona que retorna cache local + cache do banco
        return getCachedDailyTimes()
    }
    
    func getAverageTime() async -> TimeInterval {
        let dailyTimes = await getAllDailyTimes()
        guard !dailyTimes.isEmpty else { return 0 }
        
        let totalTime = dailyTimes.reduce(0) { $0 + $1.time }
        return totalTime / Double(dailyTimes.count)
    }
    
    func getAverageTimeSync() -> TimeInterval {
        let dailyTimes = getAllDailyTimesSync()
        guard !dailyTimes.isEmpty else { return 0 }
        
        let totalTime = dailyTimes.reduce(0) { $0 + $1.time }
        return totalTime / Double(dailyTimes.count)
    }
    
    private func upsertCachedSession(_ session: SupabaseManager.FocusSessionRecord) {
        cachedSessions[session.date] = session.duration_minutes
        
        if let date = parseDate(session.date) {
            let remoteSeconds = TimeInterval(session.duration_minutes * 60)
            let localTime = AppBlockingTracker.shared.getTotalBlockingTime(for: date)
            let syncedValue = min(localTime, remoteSeconds)
            setSyncedLocalSeconds(syncedValue, for: formatDate(date))
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func getSyncedLocalSeconds(for dateKey: String) -> TimeInterval {
        return userDefaults.double(forKey: "\(syncedLocalPrefix)\(dateKey)")
    }
    
    private func setSyncedLocalSeconds(_ value: TimeInterval, for dateKey: String) {
        userDefaults.set(value, forKey: "\(syncedLocalPrefix)\(dateKey)")
    }
}

