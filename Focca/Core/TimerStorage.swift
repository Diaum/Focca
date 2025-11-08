import Foundation

class TimerStorage {
    static let shared = TimerStorage()

    private let userDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard

    private init() {}
    
    func initializeFirstLaunch() {
        if userDefaults.object(forKey: "first_launch_date") == nil {
            let today = Calendar.current.startOfDay(for: Date())
            userDefaults.set(today, forKey: "first_launch_date")
        }
    }
    
    func getDailyTime(for date: Date) -> TimeInterval {
        let dateKey = formatDate(date)
        
        // Primeiro tenta buscar dados do AppBlockingTracker
        let totalTime = AppBlockingTracker.shared.getTotalBlockingTime(for: date)
        
        // Se encontrou dados do AppBlockingTracker, retorna
        if totalTime > 0 {
            return totalTime
        }
        
        // Fallback para dados antigos de daily_time_
        let oldTime = userDefaults.double(forKey: "daily_time_\(dateKey)")
        if oldTime > 0 {
            return oldTime
        }
        
        return 0
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
    
    func getAllDailyTimes() -> [(date: Date, time: TimeInterval)] {
        var result: [(date: Date, time: TimeInterval)] = []
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        // Busca dados de bloqueio de apps do AppBlockingTracker
        let blockingKeys = allKeys.filter { $0.hasPrefix("app_blocking_") }
        
        // Cria um conjunto de datas já processadas para evitar duplicatas
        var processedDates = Set<String>()
        
        for key in blockingKeys {
            let dateString = key.replacingOccurrences(of: "app_blocking_", with: "")
            
            // Evita processar a mesma data múltiplas vezes
            if processedDates.contains(dateString) {
                continue
            }
            processedDates.insert(dateString)
            
            if let date = parseDate(dateString) {
                // Usa o método público do AppBlockingTracker para obter o tempo total
                let totalTime = AppBlockingTracker.shared.getTotalBlockingTime(for: date)
                
                if totalTime > 0 {
                    result.append((date: date, time: totalTime))
                }
            }
        }
        
        // Também busca dados antigos de daily_time_ para compatibilidade
        let timeKeys = allKeys.filter { $0.hasPrefix("daily_time_") }
        for key in timeKeys {
            let time = userDefaults.double(forKey: key)
            if time > 0 {
                let dateString = key.replacingOccurrences(of: "daily_time_", with: "")
                if let date = parseDate(dateString) {
                    // Verifica se já existe uma entrada para esta data
                    if let existingIndex = result.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                        // Se já existe, usa o maior valor (não soma, para evitar duplicação)
                        if time > result[existingIndex].time {
                            result[existingIndex] = (date: result[existingIndex].date, time: time)
                        }
                    } else {
                        // Se não existe, adiciona nova entrada
                        result.append((date: date, time: time))
                    }
                }
            }
        }
        
        result.sort { $0.date > $1.date }
        return result
    }
    
    func getAverageTime() -> TimeInterval {
        let dailyTimes = getAllDailyTimes()
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

