import Foundation

class TimerStorage {
    static let shared = TimerStorage()

    private let userDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
    private var cachedSessions: [String: Int] = [:]
    private var lastFetchDate: Date?
    private let cacheValidityInterval: TimeInterval = 300 // 5 minutos

    private init() {}
    
    func initializeFirstLaunch() {
        if userDefaults.object(forKey: "first_launch_date") == nil {
            let today = Calendar.current.startOfDay(for: Date())
            userDefaults.set(today, forKey: "first_launch_date")
        }
        cleanOldLocalData()
    }
    
    func getDailyTime(for date: Date) -> TimeInterval {
        let dateKey = formatDate(date)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        let daysDifference = calendar.dateComponents([.day], from: targetDate, to: today).day ?? 0
        
        // Se for hoje ou dos últimos 7 dias, busca do AppBlockingTracker primeiro
        if daysDifference <= 7 {
            let totalTime = AppBlockingTracker.shared.getTotalBlockingTime(for: date)
            if totalTime > 0 {
                return totalTime
            }
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
                    cachedSessions[session.date] = session.duration_minutes
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
        var result: [(date: Date, time: TimeInterval)] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        // Busca dados do banco de dados primeiro
        do {
            let sessions = try await SupabaseManager.shared.getSessions()
            for session in sessions {
                if let date = parseDate(session.date) {
                    let time = TimeInterval(session.duration_minutes * 60)
                    result.append((date: date, time: time))
                }
            }
        } catch {
            print("⚠️ [TimerStorage] Erro ao buscar do banco, usando cache local: \(error.localizedDescription)")
            
            // Fallback: busca dados locais dos últimos 7 dias
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
            
            // Também busca dados antigos de daily_time_ (apenas últimos 7 dias)
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
        }
        
        result.sort { $0.date > $1.date }
        return result
    }
    
    func getAllDailyTimesSync() -> [(date: Date, time: TimeInterval)] {
        // Versão síncrona para compatibilidade (retorna apenas últimos 7 dias)
        var result: [(date: Date, time: TimeInterval)] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
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
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}

