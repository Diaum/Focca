import Foundation
import Combine

class StatsAchievementManager: ObservableObject {
    static let shared = StatsAchievementManager()
    
    private let userDefaults = UserDefaults.standard
    
    @Published var hasNewAchievements: Bool = false
    
    private init() {
        // Verifica conquistas no init, mas também será chamado quando necessário
        updateAchievements()
    }
    
    // Método público para atualizar conquistas (chamado quando dados mudam)
    func updateAchievements() {
        checkAchievements()
    }
    
    // MARK: - Achievement Keys
    private enum AchievementKey: String {
        case twentyFourHoursTotal = "stats_24h_total_achieved"
        case twentyFourHoursViewed = "stats_24h_total_viewed"
        case threeDayStreak = "stats_3day_streak_achieved"
        case threeDayStreakViewed = "stats_3day_streak_viewed"
        case hundredHoursTotal = "stats_100h_total_achieved"
        case hundredHoursViewed = "stats_100h_total_viewed"
    }
    
    // MARK: - Check Achievements
    func checkAchievements() {
        let dailyTimes = TimerStorage.shared.getAllDailyTimes()
        let totalTime = dailyTimes.reduce(0) { $0 + $1.time }
        let streak = calculateCurrentStreak(dailyTimes: dailyTimes)
        
        var hasNew = false
        
        // Verifica 24h total
        if totalTime >= 24 * 3600 {
            if !userDefaults.bool(forKey: AchievementKey.twentyFourHoursTotal.rawValue) {
                userDefaults.set(true, forKey: AchievementKey.twentyFourHoursTotal.rawValue)
                hasNew = true
            } else if !userDefaults.bool(forKey: AchievementKey.twentyFourHoursViewed.rawValue) {
                hasNew = true
            }
        }
        
        // Verifica 3 dias de streak
        if streak >= 3 {
            if !userDefaults.bool(forKey: AchievementKey.threeDayStreak.rawValue) {
                userDefaults.set(true, forKey: AchievementKey.threeDayStreak.rawValue)
                hasNew = true
            } else if !userDefaults.bool(forKey: AchievementKey.threeDayStreakViewed.rawValue) {
                hasNew = true
            }
        }
        
        // Verifica 100h total
        if totalTime >= 100 * 3600 {
            if !userDefaults.bool(forKey: AchievementKey.hundredHoursTotal.rawValue) {
                userDefaults.set(true, forKey: AchievementKey.hundredHoursTotal.rawValue)
                hasNew = true
            } else if !userDefaults.bool(forKey: AchievementKey.hundredHoursViewed.rawValue) {
                hasNew = true
            }
        }
        
        DispatchQueue.main.async {
            self.hasNewAchievements = hasNew
        }
    }
    
    // MARK: - Mark as Viewed
    func markAchievementsAsViewed() {
        let dailyTimes = TimerStorage.shared.getAllDailyTimes()
        let totalTime = dailyTimes.reduce(0) { $0 + $1.time }
        let streak = calculateCurrentStreak(dailyTimes: dailyTimes)
        
        // Marca como visualizado apenas se a conquista foi atingida
        if totalTime >= 24 * 3600 {
            userDefaults.set(true, forKey: AchievementKey.twentyFourHoursViewed.rawValue)
        }
        
        if streak >= 3 {
            userDefaults.set(true, forKey: AchievementKey.threeDayStreakViewed.rawValue)
        }
        
        if totalTime >= 100 * 3600 {
            userDefaults.set(true, forKey: AchievementKey.hundredHoursViewed.rawValue)
        }
        
        checkAchievements()
    }
    
    // MARK: - Calculate Streak
    private func calculateCurrentStreak(dailyTimes: [(date: Date, time: TimeInterval)]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let minTimePerDay: TimeInterval = 3600 // 1 hora
        
        guard !dailyTimes.isEmpty else { return 0 }
        
        // Cria um dicionário para acesso rápido por data
        var timeByDate: [Date: TimeInterval] = [:]
        for (date, time) in dailyTimes {
            let dayStart = calendar.startOfDay(for: date)
            if let existingTime = timeByDate[dayStart] {
                timeByDate[dayStart] = max(existingTime, time)
            } else {
                timeByDate[dayStart] = time
            }
        }
        
        // O streak SEMPRE começa de hoje
        let todayTime = timeByDate[today] ?? 0
        guard todayTime >= minTimePerDay else { return 0 }
        
        // Conta os dias consecutivos a partir de hoje, indo para trás
        var streak = 1
        var currentDate = today
        
        while true {
            if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                let previousDayStart = calendar.startOfDay(for: previousDay)
                if let time = timeByDate[previousDayStart], time >= minTimePerDay {
                    streak += 1
                    currentDate = previousDayStart
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return streak
    }
}

