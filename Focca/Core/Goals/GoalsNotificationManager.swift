import Foundation
import UserNotifications

class GoalsNotificationManager {
    static let shared = GoalsNotificationManager()
    
    private init() {}
    
    // MARK: - Validações
    
    func validateWeeklyGoal(hours: Int, minutes: Int) -> (isValid: Bool, errorMessage: String?) {
        let totalMinutes = hours * 60 + minutes
        
        // Mínimo de 1 hora
        if totalMinutes < 60 {
            return (false, "Meta semanal deve ter pelo menos 1 hora")
        }
        
        // Mínimo de 7 horas semanais
        if totalMinutes < 420 { // 7 horas = 420 minutos
            return (false, "Meta semanal deve ter pelo menos 7 horas")
        }
        
        return (true, nil)
    }
    
    func validateMonthlyGoal(hours: Int, minutes: Int) -> (isValid: Bool, errorMessage: String?) {
        let totalMinutes = hours * 60 + minutes
        
        // Mínimo de 1 hora
        if totalMinutes < 60 {
            return (false, "Meta mensal deve ter pelo menos 1 hora")
        }
        
        // Mínimo de 30 horas mensais
        if totalMinutes < 1800 { // 30 horas = 1800 minutos
            return (false, "Meta mensal deve ter pelo menos 30 horas")
        }
        
        return (true, nil)
    }
    
    // MARK: - Notificações de Criação
    
    func sendGoalCreatedNotification(goalType: GoalType, hours: Int, minutes: Int, currentProgress: TimeInterval) async {
        let status = await NotificationManager.shared.checkAuthorizationStatus()
        guard status == .authorized else {
            return
        }
        
        await MainActor.run {
            let goalTime = TimeInterval(hours * 3600 + minutes * 60)
            let percentage = goalTime > 0 ? Int((currentProgress / goalTime) * 100) : 0
            
            let title = goalType == .weekly ? "Meta Semanal Criada! 🎯" : "Meta Mensal Criada! 🎯"
            let timeText = formatTime(hours: hours, minutes: minutes)
            let goalTypeText = goalType == .weekly ? "semanal" : "mensal"
            let body = "Sua meta \(goalTypeText) de \(timeText) foi definida. Você está atualmente em \(percentage)% da sua meta."
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.badge = 1
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let identifier = "goal_\(goalType.rawValue)_created_\(Date().timeIntervalSince1970)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ [GoalsNotification] Error sending creation notification: \(error.localizedDescription)")
                } else {
                    print("✅ [GoalsNotification] Goal created notification sent - \(percentage)%")
                }
            }
        }
    }
    
    // MARK: - Notificações de Progresso
    
    func scheduleProgressNotifications(goalType: GoalType, hours: Int, minutes: Int, startDate: Date) async {
        let status = await NotificationManager.shared.checkAuthorizationStatus()
        guard status == .authorized else {
            return
        }
        
        await MainActor.run {
            let calendar = Calendar.current
            let goalTime = TimeInterval(hours * 3600 + minutes * 60)
            let halfGoal = goalTime / 2
            
            // Cancela notificações antigas deste goal
            cancelProgressNotifications(goalType: goalType)
            
            // Agenda verificação diária para detectar quando atingir 50% e 100%
            scheduleDailyProgressCheck(goalType: goalType, hours: hours, minutes: minutes, startDate: startDate)
        }
    }
    
    private func scheduleDailyProgressCheck(goalType: GoalType, hours: Int, minutes: Int, startDate: Date) {
        // Not needed - we'll check progress when app enters foreground and periodically
        // This method is kept for future use if needed
    }
    
    // MARK: - Verificação de Progresso
    
    func checkAndSendProgressNotifications(goalType: GoalType, hours: Int, minutes: Int, startDate: Date) async {
        let status = await NotificationManager.shared.checkAuthorizationStatus()
        guard status == .authorized else {
            return
        }
        
        await MainActor.run {
            let calendar = Calendar.current
            let startDay = calendar.startOfDay(for: startDate)
            let today = calendar.startOfDay(for: Date())
            let endDate = calendar.date(byAdding: .day, value: goalType == .weekly ? 7 : 30, to: startDay)!
            
            // Calcula progresso atual
            var totalTime: TimeInterval = 0
            var currentDate = startDay
            
            while currentDate <= today && currentDate <= endDate {
                totalTime += TimerStorage.shared.getDailyTime(for: currentDate)
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            }
            
            let goalTime = TimeInterval(hours * 3600 + minutes * 60)
            let percentage = goalTime > 0 ? (totalTime / goalTime) * 100 : 0
            
            // Verifica se já foi notificado sobre 50% e 100%
            let userDefaults = UserDefaults.standard
            let halfNotifiedKey = "goal_\(goalType.rawValue)_half_notified"
            let fullNotifiedKey = "goal_\(goalType.rawValue)_full_notified"
            
            let halfNotified = userDefaults.bool(forKey: halfNotifiedKey)
            let fullNotified = userDefaults.bool(forKey: fullNotifiedKey)
            
            // Notificação de 50%
            if percentage >= 50 && !halfNotified {
                sendProgressNotification(goalType: goalType, percentage: 50, currentProgress: totalTime, goalTime: goalTime)
                userDefaults.set(true, forKey: halfNotifiedKey)
            }
            
            // Notificação de 100%
            if percentage >= 100 && !fullNotified {
                sendProgressNotification(goalType: goalType, percentage: 100, currentProgress: totalTime, goalTime: goalTime)
                userDefaults.set(true, forKey: fullNotifiedKey)
                
                // Increment completed goals counter
                let completedKey = goalType == .weekly ? "weekly_goals_completed" : "monthly_goals_completed"
                let currentCount = userDefaults.integer(forKey: completedKey)
                userDefaults.set(currentCount + 1, forKey: completedKey)
                print("🎯 [GoalsNotification] \(goalType.rawValue.capitalized) goal completed! Total: \(currentCount + 1)")
                
                // Check for completion awards
                if goalType == .weekly {
                    AwardManager.shared.checkWeeklyGoalCompletedAward()
                } else {
                    AwardManager.shared.checkMonthlyGoalCompletedAward()
                }
            }
        }
    }
    
    private func sendProgressNotification(goalType: GoalType, percentage: Int, currentProgress: TimeInterval, goalTime: TimeInterval) {
        let title: String
        let body: String
        
        if percentage == 100 {
            title = goalType == .weekly ? "Meta Semanal Atingida! 🎉" : "Meta Mensal Atingida! 🎉"
            let goalTypeText = goalType == .weekly ? "semanal" : "mensal"
            body = "Parabéns! Você atingiu 100% da sua meta \(goalTypeText)!"
        } else {
            title = "Na Metade do Caminho! 🎯"
            let progressText = formatTimeInterval(currentProgress)
            let goalTypeText = goalType == .weekly ? "semanal" : "mensal"
            body = "Você está em 50% da sua meta \(goalTypeText)! Progresso atual: \(progressText)"
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "goal_\(goalType.rawValue)_\(percentage)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [GoalsNotification] Error sending progress notification: \(error.localizedDescription)")
            } else {
                print("✅ [GoalsNotification] Progress notification sent - \(percentage)%")
            }
        }
    }
    
    // MARK: - Notificação Inteligente
    
    func checkAndSendSmartNotification(goalType: GoalType, hours: Int, minutes: Int, startDate: Date) async {
        let status = await NotificationManager.shared.checkAuthorizationStatus()
        guard status == .authorized else {
            return
        }
        
        await MainActor.run {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            var startDay: Date
            var endDate: Date
            
            if goalType == .weekly {
                startDay = calendar.startOfDay(for: startDate)
                endDate = calendar.date(byAdding: .day, value: 7, to: startDay)!
            } else {
                // Monthly: use calendar month
                startDay = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate))!
                endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDay)!
            }
            
            // Calcula progresso atual
            var totalTime: TimeInterval = 0
            var currentDate = startDay
            let maxDate = min(endDate, today)
            
            while currentDate <= maxDate {
                totalTime += TimerStorage.shared.getDailyTime(for: currentDate)
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            }
            
            // Calcula média diária
            let averageDaily = TimerStorage.shared.getAverageTime()
            
            // Dias já passados e dias restantes
            let daysPassed = max(1, calendar.dateComponents([.day], from: startDay, to: today).day ?? 1)
            let daysRemaining = max(1, calendar.dateComponents([.day], from: today, to: endDate).day ?? 1)
            
            let goalTime = TimeInterval(hours * 3600 + minutes * 60)
            let remainingTime = goalTime - totalTime
            
            // Só envia se ainda há tempo restante e dias restantes > 0
            guard daysRemaining > 0 && remainingTime > 0 else {
                return
            }
            
            // Projeção baseada na média diária
            let projectedTotal = totalTime + (averageDaily * Double(daysRemaining))
            
            // Verifica se vai conseguir atingir a meta (com margem de 5%)
            let threshold = goalTime * 0.95
            if projectedTotal < threshold {
                let neededDaily = remainingTime / Double(daysRemaining)
                let currentAverageTotalMinutes = Int(averageDaily / 60)
                let neededTotalMinutes = Int(ceil(neededDaily / 60))
                
                // Formata média diária atual
                let currentAverageHours = currentAverageTotalMinutes / 60
                let currentAverageMins = currentAverageTotalMinutes % 60
                let currentAverageText = currentAverageTotalMinutes >= 60 
                    ? "\(currentAverageHours)h \(currentAverageMins)m"
                    : "\(currentAverageTotalMinutes) minutos"
                
                // Formata tempo necessário
                let neededHours = neededTotalMinutes / 60
                let neededMins = neededTotalMinutes % 60
                let neededText = neededTotalMinutes >= 60
                    ? "\(neededHours)h \(neededMins)m"
                    : "\(neededTotalMinutes) minutos"
                
                // Verifica se já foi notificado hoje
                let userDefaults = UserDefaults.standard
                let lastSmartNotificationKey = "goal_\(goalType.rawValue)_smart_notification_date"
                let lastNotificationDate = userDefaults.double(forKey: lastSmartNotificationKey)
                let todayTimestamp = today.timeIntervalSince1970
                
                // Só envia se não foi notificado hoje
                if lastNotificationDate < todayTimestamp {
                    let title = "Alerta de Meta ⚠️"
                    let goalText = formatTime(hours: hours, minutes: minutes)
                    let goalTypeText = goalType == .weekly ? "semanal" : "mensal"
                    let body = "Defini uma meta \(goalTypeText) de \(goalText) e meu bloqueio diário atual é \(currentAverageText). Aumente seu tempo longe dos apps para \(neededText) por dia."
                    
                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = body
                    content.sound = .default
                    content.badge = 1
                    
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let identifier = "goal_\(goalType.rawValue)_smart_\(Date().timeIntervalSince1970)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("❌ [GoalsNotification] Error sending smart notification: \(error.localizedDescription)")
                        } else {
                            print("✅ [GoalsNotification] Smart notification sent")
                            userDefaults.set(todayTimestamp, forKey: lastSmartNotificationKey)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Cancelamento
    
    func cancelProgressNotifications(goalType: GoalType) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.contains("goal_\(goalType.rawValue)_") }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            print("🗑️ [GoalsNotification] Cancelled \(identifiers.count) notifications for \(goalType.rawValue) goal")
        }
    }
    
    func resetProgressFlags(goalType: GoalType) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(false, forKey: "goal_\(goalType.rawValue)_half_notified")
        userDefaults.set(false, forKey: "goal_\(goalType.rawValue)_full_notified")
    }
    
    // MARK: - Helpers
    
    private func formatTime(hours: Int, minutes: Int) -> String {
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }
    
    enum GoalType: String {
        case weekly = "weekly"
        case monthly = "monthly"
    }
}

