import Foundation
import Combine

class AwardManager: ObservableObject {
    static let shared = AwardManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
    private let awardsKey = "unlocked_awards"
    
    @Published var unlockedAwards: Set<String> = []
    @Published var hasNewAwards: Bool = false
    
    private init() {
        loadUnlockedAwards()
        checkNewAwards()
    }
    
    func loadUnlockedAwards() {
        if let data = userDefaults.data(forKey: awardsKey),
           let awards = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedAwards = awards
        }
    }
    
    func isAwardUnlocked(_ awardId: String) -> Bool {
        return unlockedAwards.contains(awardId)
    }
    
    func unlockAward(_ awardId: String) {
        guard !unlockedAwards.contains(awardId) else { return }
        
        unlockedAwards.insert(awardId)
        saveUnlockedAwards()
        
        // Marca que há novos awards não visualizados
        markNewAward()
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    private func markNewAward() {
        let lastViewedCount = userDefaults.integer(forKey: "awards_last_viewed_count")
        let currentCount = unlockedAwards.count
        
        if currentCount > lastViewedCount {
            hasNewAwards = true
            userDefaults.set(true, forKey: "has_new_awards")
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    private func checkNewAwards() {
        let lastViewedCount = userDefaults.integer(forKey: "awards_last_viewed_count")
        let currentCount = unlockedAwards.count
        hasNewAwards = currentCount > lastViewedCount || userDefaults.bool(forKey: "has_new_awards")
    }
    
    func markAwardsAsViewed() {
        let currentCount = unlockedAwards.count
        userDefaults.set(currentCount, forKey: "awards_last_viewed_count")
        userDefaults.set(false, forKey: "has_new_awards")
        hasNewAwards = false
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    private func saveUnlockedAwards() {
        if let data = try? JSONEncoder().encode(unlockedAwards) {
            userDefaults.set(data, forKey: awardsKey)
        }
    }
    
    func checkFocusDurationAward(duration: TimeInterval, awardId: String) {
        let awards: [String: TimeInterval] = [
            "1_hour_focus": 3600,
            "30_min_focus": 1800
        ]
        
        guard let requiredDuration = awards[awardId] else { return }
        
        if duration >= requiredDuration && !isAwardUnlocked(awardId) {
            unlockAward(awardId)
            
            let minutes = Int(requiredDuration / 60)
            let hours = minutes / 60
            
            let timeString: String
            if hours > 0 {
                timeString = "\(hours) hour\(hours > 1 ? "s" : "")"
            } else {
                timeString = "\(minutes) minute\(minutes > 1 ? "s" : "")"
            }
            
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've been focused for \(timeString)!"
            )
        }
    }
    
    func checkAllAwards() {
        checkHistoricalAwards()
        checkStreakAwards()
        checkScheduleAward()
        checkGoalAwards()
    }
    
    private func checkHistoricalAwards() {
        let dailyTimes = TimerStorage.shared.getAllDailyTimes()
        
        var maxSingleSession: TimeInterval = 0
        var totalTime: TimeInterval = 0
        
        for (_, time) in dailyTimes {
            totalTime += time
            if time > maxSingleSession {
                maxSingleSession = time
            }
        }
        
        if maxSingleSession >= 3600 && !isAwardUnlocked("1_hour_focus") {
            unlockAward("1_hour_focus")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've been focused for 1 hour!"
            )
        }
        
        if maxSingleSession >= 1800 && !isAwardUnlocked("30_min_focus") {
            unlockAward("30_min_focus")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've been focused for 30 minutes!"
            )
        }
        
        let totalHours = totalTime / 3600
        if totalHours >= 10 && !isAwardUnlocked("10_hours_total") {
            unlockAward("10_hours_total")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've accumulated 10 hours of focused time!"
            )
        }
        
        if totalHours >= 24 && !isAwardUnlocked("24_hours_total") {
            unlockAward("24_hours_total")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've accumulated 24 hours of focused time!"
            )
        }
        
        if totalHours >= 48 && !isAwardUnlocked("48_hours_total") {
            unlockAward("48_hours_total")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've accumulated 48 hours of focused time!"
            )
        }
        
        if totalHours >= 72 && !isAwardUnlocked("72_hours_total") {
            unlockAward("72_hours_total")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've accumulated 72 hours of focused time!"
            )
        }
    }
    
    private func checkStreakAwards() {
        let dailyTimes = TimerStorage.shared.getAllDailyTimes()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard !dailyTimes.isEmpty else { return }
        
        let minTimePerDay: TimeInterval = 3600
        
        var streak = 0
        var currentDate = today
        
        while true {
            if let dayData = dailyTimes.first(where: { calendar.isDate($0.date, inSameDayAs: currentDate) }),
               dayData.time >= minTimePerDay {
                streak += 1
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                    currentDate = calendar.startOfDay(for: previousDay)
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        if streak >= 7 && !isAwardUnlocked("7_day_streak") {
            unlockAward("7_day_streak")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've maintained a 7-day streak with at least 1 hour per day!"
            )
        }
        
        if streak >= 15 && !isAwardUnlocked("15_day_streak") {
            unlockAward("15_day_streak")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've maintained a 15-day streak with at least 1 hour per day!"
            )
        }
        
        if streak >= 30 && !isAwardUnlocked("30_day_streak") {
            unlockAward("30_day_streak")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've maintained a 30-day streak with at least 1 hour per day!"
            )
        }
    }
    
    private func checkScheduleAward() {
        guard !isAwardUnlocked("scheduled_session") else { return }
        
        let hasActivatedSchedule = userDefaults.bool(forKey: "schedule_has_been_activated")
        
        if hasActivatedSchedule {
            unlockAward("scheduled_session")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've started a focus session using a schedule!"
            )
        }
    }
    
    func markScheduleActivated() {
        userDefaults.set(true, forKey: "schedule_has_been_activated")
        checkScheduleAward()
    }
    
    // MARK: - Goal Awards
    
    func checkGoalCreatedAward() {
        guard !isAwardUnlocked("create_goal") else { return }
        
        // Use UserDefaults.standard to match GoalsView
        let standardDefaults = UserDefaults.standard
        let hasWeeklyGoal = standardDefaults.bool(forKey: "weekly_goal_exists")
        let hasMonthlyGoal = standardDefaults.bool(forKey: "monthly_goal_exists")
        
        print("🎯 [AwardManager] Checking goal creation award - Weekly: \(hasWeeklyGoal), Monthly: \(hasMonthlyGoal)")
        
        if hasWeeklyGoal || hasMonthlyGoal {
            unlockAward("create_goal")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've created your first goal!"
            )
            print("✅ [AwardManager] Goal creation award unlocked!")
        }
    }
    
    func checkWeeklyGoalCompletedAward() {
        guard !isAwardUnlocked("complete_weekly_goal") else { return }
        
        // Use UserDefaults.standard to match GoalsNotificationManager
        let standardDefaults = UserDefaults.standard
        let weeklyGoalsCompleted = standardDefaults.integer(forKey: "weekly_goals_completed")
        
        print("🎯 [AwardManager] Checking weekly goal completion award - Completed: \(weeklyGoalsCompleted)")
        
        if weeklyGoalsCompleted >= 1 {
            unlockAward("complete_weekly_goal")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've completed your first weekly goal!"
            )
            print("✅ [AwardManager] Weekly goal completion award unlocked!")
        }
    }
    
    func checkMonthlyGoalCompletedAward() {
        guard !isAwardUnlocked("complete_monthly_goal") else { return }
        
        // Use UserDefaults.standard to match GoalsNotificationManager
        let standardDefaults = UserDefaults.standard
        let monthlyGoalsCompleted = standardDefaults.integer(forKey: "monthly_goals_completed")
        
        print("🎯 [AwardManager] Checking monthly goal completion award - Completed: \(monthlyGoalsCompleted)")
        
        if monthlyGoalsCompleted >= 1 {
            unlockAward("complete_monthly_goal")
            NotificationManager.shared.sendInfoNotification(
                title: "🎉 Award Unlocked!",
                body: "You've completed your first monthly goal!"
            )
            print("✅ [AwardManager] Monthly goal completion award unlocked!")
        }
    }
    
    private func checkGoalAwards() {
        checkGoalCreatedAward()
        checkWeeklyGoalCompletedAward()
        checkMonthlyGoalCompletedAward()
    }
}

