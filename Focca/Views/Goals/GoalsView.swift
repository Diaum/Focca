import SwiftUI
import UserNotifications
import UIKit

struct GoalsView: View {
    @Binding var selectedTab: Int
    let isBlocked: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var weeklyGoalHours: Int = 10
    @State private var weeklyGoalMinutes: Int = 0
    @State private var monthlyGoalHours: Int = 40
    @State private var monthlyGoalMinutes: Int = 0
    @State private var hasWeeklyGoal: Bool = false
    @State private var hasMonthlyGoal: Bool = false
    @State private var isEditingWeekly: Bool = false
    @State private var isEditingMonthly: Bool = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var weeklyGoalStartDate: Date?
    @State private var monthlyGoalStartDate: Date?
    @State private var showEditWarning: Bool = false
    @State private var pendingEditType: EditType? = nil
    @State private var showValidationError: Bool = false
    @State private var validationErrorMessage: String = ""
    
    enum EditType {
        case weekly
        case monthly
    }
    
    private var isEditingAnyGoal: Bool {
        return isEditingWeekly || isEditingMonthly
    }
    
    var body: some View {
        ZStack {
            (isBlocked
                ? Color(hex: "0A0A0A")
                : Color(hex: "EDE7E6"))
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header com botão de voltar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                            .frame(width: 44, height: 44)
                            .background(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                VStack(spacing: 4) {
                    Text("Metas")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
                
                if GoalsManager.shared.areGoalsEnabled {
                    VStack(spacing: 20) {
                        WeeklyGoalCard(
                            hours: $weeklyGoalHours,
                            minutes: $weeklyGoalMinutes,
                            isBlocked: isBlocked,
                            hasGoal: $hasWeeklyGoal,
                            isEditing: $isEditingWeekly,
                            startDate: weeklyGoalStartDate,
                            isOtherGoalEditing: isEditingMonthly,
                            onEditRequest: {
                                pendingEditType = .weekly
                                showEditWarning = true
                            },
                            onSave: {
                                saveWeeklyGoal()
                            }
                        )
                        
                        MonthlyGoalCard(
                            hours: $monthlyGoalHours,
                            minutes: $monthlyGoalMinutes,
                            isBlocked: isBlocked,
                            hasGoal: $hasMonthlyGoal,
                            isEditing: $isEditingMonthly,
                            startDate: monthlyGoalStartDate,
                            isOtherGoalEditing: isEditingWeekly,
                            onEditRequest: {
                                pendingEditType = .monthly
                                showEditWarning = true
                            },
                            onSave: {
                                saveMonthlyGoal()
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 105)
                    .alert("Aviso de Exclusão de Meta", isPresented: $showEditWarning) {
                        Button("Cancelar", role: .cancel) {
                            pendingEditType = nil
                        }
                        Button("Excluir", role: .destructive) {
                            if let editType = pendingEditType {
                                switch editType {
                                case .weekly:
                                    // Delete weekly goal
                                    let userDefaults = UserDefaults.standard
                                    userDefaults.set(false, forKey: "weekly_goal_exists")
                                    userDefaults.removeObject(forKey: "weekly_goal_hours")
                                    userDefaults.removeObject(forKey: "weekly_goal_minutes")
                                    userDefaults.removeObject(forKey: "weekly_goal_start_date")
                                    hasWeeklyGoal = false
                                    weeklyGoalHours = 10
                                    weeklyGoalMinutes = 0
                                    weeklyGoalStartDate = nil
                                    isEditingWeekly = false
                                    print("🗑️ [Goals] Weekly goal deleted")
                                case .monthly:
                                    // Delete monthly goal
                                    let userDefaults = UserDefaults.standard
                                    userDefaults.set(false, forKey: "monthly_goal_exists")
                                    userDefaults.removeObject(forKey: "monthly_goal_hours")
                                    userDefaults.removeObject(forKey: "monthly_goal_minutes")
                                    userDefaults.removeObject(forKey: "monthly_goal_start_date")
                                    hasMonthlyGoal = false
                                    monthlyGoalHours = 40
                                    monthlyGoalMinutes = 0
                                    monthlyGoalStartDate = nil
                                    isEditingMonthly = false
                                    print("🗑️ [Goals] Monthly goal deleted")
                                }
                            }
                            pendingEditType = nil
                        }
                    } message: {
                        Text("Excluir uma meta é irreversível. Todo o progresso acumulado para o período atual será perdido. Tem certeza que deseja excluir esta meta?")
                    }
                    .alert("Meta Inválida", isPresented: $showValidationError) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(validationErrorMessage)
                    }
                } else {
                    VStack(spacing: 20) {
                        // Disabled Weekly Goal Card
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 18))
                                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8"))
                                    
                                    Text("Meta Semanal")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8"))
                                    
                                    Spacer()
                                }
                                
                                Text("O tempo mínimo semanal que você idealmente deseja ficar longe dos seus apps.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Text("As metas estão desabilitadas. Ative-as em Ajustes para usar este recurso.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 20)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isBlocked ? Color(hex: "2C2C2E") : Color(hex: "F5F5F5"))
                                .shadow(color: Color.black.opacity(isBlocked ? 0.2 : 0.02), radius: 3, x: 0, y: 1)
                        )
                        .allowsHitTesting(false)
                        
                        // Disabled Monthly Goal Card
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 18))
                                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8"))
                                    
                                    Text("Meta Mensal")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8"))
                                    
                                    Spacer()
                                }
                                
                                Text("O tempo mínimo mensal que você idealmente deseja ficar longe dos seus apps.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Text("As metas estão desabilitadas. Ative-as em Ajustes para usar este recurso.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 20)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isBlocked ? Color(hex: "2C2C2E") : Color(hex: "F5F5F5"))
                                .shadow(color: Color.black.opacity(isBlocked ? 0.2 : 0.02), radius: 3, x: 0, y: 1)
                        )
                        .allowsHitTesting(false)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 105)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 16)
            
            VStack(spacing: 0) {
                Spacer()
                WhiteRoundedBottomPlain(isBlocked: isBlocked)
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -48)
            }
            .zIndex(1)
        }
        .preferredColorScheme(isBlocked ? .dark : .light)
        .onAppear {
            checkNotificationStatus()
            loadGoals()
            checkAndRecalculatePeriods()
            // Force update progress when view appears - delay to ensure cards are ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NotificationCenter.default.post(name: NSNotification.Name("UpdateWeeklyGoalProgress"), object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("UpdateMonthlyGoalProgress"), object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkNotificationStatus()
            checkAndRecalculatePeriods()
            // Force update progress when app comes to foreground
            NotificationCenter.default.post(name: NSNotification.Name("UpdateWeeklyGoalProgress"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("UpdateMonthlyGoalProgress"), object: nil)
            
            // Check progress notifications and smart notifications
            Task {
                if hasWeeklyGoal, let startDate = weeklyGoalStartDate {
                    await GoalsNotificationManager.shared.checkAndSendProgressNotifications(
                        goalType: .weekly,
                        hours: weeklyGoalHours,
                        minutes: weeklyGoalMinutes,
                        startDate: startDate
                    )
                }
                
                if hasMonthlyGoal, let startDate = monthlyGoalStartDate {
                    let calendar = Calendar.current
                    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate))!
                    await GoalsNotificationManager.shared.checkAndSendProgressNotifications(
                        goalType: .monthly,
                        hours: monthlyGoalHours,
                        minutes: monthlyGoalMinutes,
                        startDate: monthStart
                    )
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GoalsEnabledChanged"))) { _ in
            // Reload goals state when enabled/disabled
            loadGoals()
        }
    }
    
    private func checkNotificationStatus() {
        Task {
            let status = await NotificationManager.shared.checkAuthorizationStatus()
            await MainActor.run {
                notificationStatus = status
                if status != .authorized {
                    requestNotificationPermission()
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        Task {
            _ = await NotificationManager.shared.requestAuthorization()
        }
    }
    
    private func loadGoals() {
        let userDefaults = UserDefaults.standard
        hasWeeklyGoal = userDefaults.bool(forKey: "weekly_goal_exists")
        hasMonthlyGoal = userDefaults.bool(forKey: "monthly_goal_exists")
        
        print("📋 [GoalsView] Loading goals - Weekly: \(hasWeeklyGoal), Monthly: \(hasMonthlyGoal)")
        
        if hasWeeklyGoal {
            weeklyGoalHours = userDefaults.integer(forKey: "weekly_goal_hours")
            weeklyGoalMinutes = userDefaults.integer(forKey: "weekly_goal_minutes")
            // Ensure minimum of 7 hours
            let totalMinutes = weeklyGoalHours * 60 + weeklyGoalMinutes
            if totalMinutes < 420 { // 7 hours = 420 minutes
                weeklyGoalHours = 7
                weeklyGoalMinutes = 0
                userDefaults.set(7, forKey: "weekly_goal_hours")
                userDefaults.set(0, forKey: "weekly_goal_minutes")
            }
            let startDateTimestamp = userDefaults.double(forKey: "weekly_goal_start_date")
            if startDateTimestamp > 0 {
                weeklyGoalStartDate = Date(timeIntervalSince1970: startDateTimestamp)
                print("📋 [GoalsView] Weekly goal loaded - \(weeklyGoalHours)h \(weeklyGoalMinutes)m, start: \(formatDate(weeklyGoalStartDate!))")
            }
        } else {
            // Reset to defaults if no goal exists
            weeklyGoalHours = 10
            weeklyGoalMinutes = 0
            weeklyGoalStartDate = nil
        }
        
        if hasMonthlyGoal {
            monthlyGoalHours = userDefaults.integer(forKey: "monthly_goal_hours")
            monthlyGoalMinutes = userDefaults.integer(forKey: "monthly_goal_minutes")
            let startDateTimestamp = userDefaults.double(forKey: "monthly_goal_start_date")
            if startDateTimestamp > 0 {
                monthlyGoalStartDate = Date(timeIntervalSince1970: startDateTimestamp)
                print("📋 [GoalsView] Monthly goal loaded - \(monthlyGoalHours)h \(monthlyGoalMinutes)m, start: \(formatDate(monthlyGoalStartDate!))")
            }
        } else {
            // Reset to defaults if no goal exists
            monthlyGoalHours = 40
            monthlyGoalMinutes = 0
            monthlyGoalStartDate = nil
        }
        
        // Trigger progress update after loading goals
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: NSNotification.Name("UpdateWeeklyGoalProgress"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("UpdateMonthlyGoalProgress"), object: nil)
        }
    }
    
    private func saveWeeklyGoal() {
        // Validate goal
        let validation = GoalsNotificationManager.shared.validateWeeklyGoal(hours: weeklyGoalHours, minutes: weeklyGoalMinutes)
        guard validation.isValid else {
            // Show error alert
            validationErrorMessage = validation.errorMessage ?? "A meta semanal deve ter no mínimo 7 horas"
            showValidationError = true
            print("❌ [Goals] Validation failed: \(validation.errorMessage ?? "Unknown error")")
            return
        }
        
        let userDefaults = UserDefaults.standard
        let isNew = !hasWeeklyGoal
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        userDefaults.set(true, forKey: "weekly_goal_exists")
        userDefaults.set(weeklyGoalHours, forKey: "weekly_goal_hours")
        userDefaults.set(weeklyGoalMinutes, forKey: "weekly_goal_minutes")
        userDefaults.synchronize() // Force sync to ensure data is saved
        
        // When editing, always reset to today (new period starts)
        if isEditingWeekly && !isNew {
            print("⚠️ [Goals] Weekly goal edited - resetting period and losing previous progress")
            weeklyGoalStartDate = today
            userDefaults.set(today.timeIntervalSince1970, forKey: "weekly_goal_start_date")
        } else if let startDate = weeklyGoalStartDate {
            let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
            if Date() >= endDate {
                weeklyGoalStartDate = today
                userDefaults.set(today.timeIntervalSince1970, forKey: "weekly_goal_start_date")
                print("📅 [Goals] Weekly goal recalculated - new period: \(formatDate(today)) to \(formatDate(calendar.date(byAdding: .day, value: 7, to: today)!))")
            } else {
                userDefaults.set(startDate.timeIntervalSince1970, forKey: "weekly_goal_start_date")
            }
        } else {
            weeklyGoalStartDate = today
            userDefaults.set(today.timeIntervalSince1970, forKey: "weekly_goal_start_date")
        }
        
        hasWeeklyGoal = true
        let wasEditing = isEditingWeekly
        isEditingWeekly = false
        
        // Reset progress flags when creating new goal or editing
        if isNew || wasEditing {
            GoalsNotificationManager.shared.resetProgressFlags(goalType: .weekly)
        }
        
        // Force update progress after saving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Trigger progress update by notifying the card
            NotificationCenter.default.post(name: NSNotification.Name("UpdateWeeklyGoalProgress"), object: nil)
        }
        
        // Send notifications (always send creation notification when saving, as editing resets the period)
        Task {
            // Get current progress (should be 0 or minimal since period was reset if editing)
            let calendar = Calendar.current
            let startDay = calendar.startOfDay(for: weeklyGoalStartDate ?? today)
            var totalTime: TimeInterval = 0
            var currentDate = startDay
            let today = calendar.startOfDay(for: Date())
            
            while currentDate <= today {
                totalTime += TimerStorage.shared.getDailyTime(for: currentDate)
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            }
            
            // Send creation notification (always, since editing resets the period)
            await GoalsNotificationManager.shared.sendGoalCreatedNotification(
                goalType: .weekly,
                hours: weeklyGoalHours,
                minutes: weeklyGoalMinutes,
                currentProgress: totalTime
            )
            
            // Schedule progress notifications
            await GoalsNotificationManager.shared.scheduleProgressNotifications(
                goalType: .weekly,
                hours: weeklyGoalHours,
                minutes: weeklyGoalMinutes,
                startDate: weeklyGoalStartDate ?? today
            )
            
        }
        
        if isNew {
            print("✅ [Goals] Weekly goal created - \(weeklyGoalHours)h \(weeklyGoalMinutes)m, start date: \(formatDate(weeklyGoalStartDate ?? today))")
            // Check for goal creation award
            AwardManager.shared.checkGoalCreatedAward()
        } else {
            print("✏️ [Goals] Weekly goal updated - \(weeklyGoalHours)h \(weeklyGoalMinutes)m, start date: \(formatDate(weeklyGoalStartDate ?? today))")
        }
    }
    
    private func saveMonthlyGoal() {
        // Validate goal
        let validation = GoalsNotificationManager.shared.validateMonthlyGoal(hours: monthlyGoalHours, minutes: monthlyGoalMinutes)
        guard validation.isValid else {
            // Show error alert
            validationErrorMessage = validation.errorMessage ?? "A meta mensal deve ter no mínimo 30 horas"
            showValidationError = true
            print("❌ [Goals] Validation failed: \(validation.errorMessage ?? "Unknown error")")
            return
        }
        
        let userDefaults = UserDefaults.standard
        let isNew = !hasMonthlyGoal
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        userDefaults.set(true, forKey: "monthly_goal_exists")
        userDefaults.set(monthlyGoalHours, forKey: "monthly_goal_hours")
        userDefaults.set(monthlyGoalMinutes, forKey: "monthly_goal_minutes")
        userDefaults.synchronize() // Force sync to ensure data is saved
        
        // Monthly goals are based on calendar months (1st to last day of month)
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        // When editing or creating, set to first day of current month
        if isEditingMonthly && !isNew {
            print("⚠️ [Goals] Monthly goal edited - resetting to current month")
            monthlyGoalStartDate = currentMonthStart
            userDefaults.set(currentMonthStart.timeIntervalSince1970, forKey: "monthly_goal_start_date")
        } else if let startDate = monthlyGoalStartDate {
            // Check if we're in a different month
            let startMonth = calendar.component(.month, from: startDate)
            let startYear = calendar.component(.year, from: startDate)
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)
            
            if startMonth != currentMonth || startYear != currentYear {
                // Month changed, reset to current month
                monthlyGoalStartDate = currentMonthStart
                userDefaults.set(currentMonthStart.timeIntervalSince1970, forKey: "monthly_goal_start_date")
                let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: currentMonthStart)!
                print("📅 [Goals] Monthly goal recalculated - new month: \(formatDate(currentMonthStart)) to \(formatDate(monthEnd))")
            } else {
                userDefaults.set(startDate.timeIntervalSince1970, forKey: "monthly_goal_start_date")
            }
        } else {
            // New goal - set to first day of current month
            monthlyGoalStartDate = currentMonthStart
            userDefaults.set(currentMonthStart.timeIntervalSince1970, forKey: "monthly_goal_start_date")
        }
        
        hasMonthlyGoal = true
        let wasEditing = isEditingMonthly
        isEditingMonthly = false
        
        // Reset progress flags when creating new goal or editing
        if isNew || wasEditing {
            GoalsNotificationManager.shared.resetProgressFlags(goalType: .monthly)
        }
        
        // Force update progress after saving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Trigger progress update by notifying the card
            NotificationCenter.default.post(name: NSNotification.Name("UpdateMonthlyGoalProgress"), object: nil)
        }
        
        // Send notifications (always send creation notification when saving, as editing resets the period)
        Task {
            // Get current progress (should be 0 or minimal since period was reset if editing)
            let calendar = Calendar.current
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthlyGoalStartDate ?? today))!
            var totalTime: TimeInterval = 0
            var currentDate = monthStart
            let today = calendar.startOfDay(for: Date())
            
            while currentDate <= today {
                totalTime += TimerStorage.shared.getDailyTime(for: currentDate)
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            }
            
            // Send creation notification (always, since editing resets the period)
            await GoalsNotificationManager.shared.sendGoalCreatedNotification(
                goalType: .monthly,
                hours: monthlyGoalHours,
                minutes: monthlyGoalMinutes,
                currentProgress: totalTime
            )
            
            // Schedule progress notifications (reuse monthStart from above)
            await GoalsNotificationManager.shared.scheduleProgressNotifications(
                goalType: .monthly,
                hours: monthlyGoalHours,
                minutes: monthlyGoalMinutes,
                startDate: monthStart
            )
            
        }
        
        if isNew {
            print("✅ [Goals] Monthly goal created - \(monthlyGoalHours)h \(monthlyGoalMinutes)m, start date: \(formatDate(monthlyGoalStartDate ?? currentMonthStart))")
            // Check for goal creation award
            AwardManager.shared.checkGoalCreatedAward()
        } else {
            print("✏️ [Goals] Monthly goal updated - \(monthlyGoalHours)h \(monthlyGoalMinutes)m, start date: \(formatDate(monthlyGoalStartDate ?? currentMonthStart))")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func checkAndRecalculatePeriods() {
        // Only recalculate if goals are enabled
        guard GoalsManager.shared.areGoalsEnabled else {
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let userDefaults = UserDefaults.standard
        
        // Check weekly goal
        if hasWeeklyGoal, let startDate = weeklyGoalStartDate {
            let startDay = calendar.startOfDay(for: startDate)
            let endDate = calendar.date(byAdding: .day, value: 7, to: startDay)!
            if Date() >= endDate {
                weeklyGoalStartDate = today
                userDefaults.set(today.timeIntervalSince1970, forKey: "weekly_goal_start_date")
                print("📅 [Goals] Weekly goal period expired, recalculated - new period: \(formatDate(today)) to \(formatDate(calendar.date(byAdding: .day, value: 7, to: today)!))")
                // Reset progress flags for new period
                GoalsNotificationManager.shared.resetProgressFlags(goalType: .weekly)
                // Force update progress after recalculating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: NSNotification.Name("UpdateWeeklyGoalProgress"), object: nil)
                }
            }
        }
        
        // Check monthly goal - reset if month changed
        if hasMonthlyGoal, let startDate = monthlyGoalStartDate {
            let startMonth = calendar.component(.month, from: startDate)
            let startYear = calendar.component(.year, from: startDate)
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)
            
            if startMonth != currentMonth || startYear != currentYear {
                // Month changed, reset to current month
                let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
                monthlyGoalStartDate = currentMonthStart
                userDefaults.set(currentMonthStart.timeIntervalSince1970, forKey: "monthly_goal_start_date")
                let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: currentMonthStart)!
                print("📅 [Goals] Monthly goal period expired, recalculated - new month: \(formatDate(currentMonthStart)) to \(formatDate(monthEnd))")
                // Reset progress flags for new period
                GoalsNotificationManager.shared.resetProgressFlags(goalType: .monthly)
                // Send creation notification for new month
                Task {
                    await GoalsNotificationManager.shared.sendGoalCreatedNotification(
                        goalType: .monthly,
                        hours: monthlyGoalHours,
                        minutes: monthlyGoalMinutes,
                        currentProgress: 0
                    )
                }
                // Force update progress after recalculating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: NSNotification.Name("UpdateMonthlyGoalProgress"), object: nil)
                }
            }
        }
    }
}



struct TimeInputView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    let isBlocked: Bool
    let maxHours: Int
    let minHours: Int
    
    init(hours: Binding<Int>, minutes: Binding<Int>, isBlocked: Bool, maxHours: Int = 999, minHours: Int = 0) {
        self._hours = hours
        self._minutes = minutes
        self.isBlocked = isBlocked
        self.maxHours = maxHours
        self.minHours = minHours
        
        // Ensure initial value is at least minimum
        let totalMinutes = hours.wrappedValue * 60 + minutes.wrappedValue
        let minMinutes = minHours * 60
        if totalMinutes < minMinutes {
            hours.wrappedValue = minHours
            minutes.wrappedValue = 0
        }
    }
    
    private var isAtMinimum: Bool {
        let totalMinutes = hours * 60 + minutes
        return totalMinutes <= (minHours * 60)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Horas")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if !isAtMinimum {
                                if hours > minHours {
                                    hours -= 1
                                } else if hours == minHours && minutes > 0 {
                                    minutes = 0
                                }
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(isAtMinimum ? (isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA")) : (isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8")))
                        }
                        .disabled(isAtMinimum)
                        
                        Text("\(hours)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                            .frame(minWidth: 60)
                        
                        Button(action: {
                            if hours < maxHours {
                                hours += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(hours >= maxHours ? (isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA")) : (isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8")))
                        }
                        .disabled(hours >= maxHours)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Text(":")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8"))
                    .padding(.top, 20)
                
                VStack(spacing: 8) {
                    Text("Minutos")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if !isAtMinimum {
                                if minutes > 0 {
                                    minutes -= 1
                                } else if hours > minHours {
                                    hours -= 1
                                    minutes = 59
                                } else if hours == minHours && minutes == 0 {
                                    // Can't go below minimum
                                }
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(isAtMinimum ? (isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA")) : (isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8")))
                        }
                        .disabled(isAtMinimum)
                        
                        Text(String(format: "%02d", minutes))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                            .frame(minWidth: 60)
                        
                        Button(action: {
                            if minutes < 59 {
                                minutes += 1
                            } else if hours < maxHours {
                                hours += 1
                                minutes = 0
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor((hours >= maxHours && minutes >= 59) ? (isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA")) : (isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8")))
                        }
                        .disabled(hours >= maxHours && minutes >= 59)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }
}

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

#Preview {
    GoalsView(selectedTab: .constant(1), isBlocked: false)
}
