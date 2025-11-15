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
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: isBlocked 
                    ? [Color(hex: "0A0A0A"), Color(hex: "0A0A0A")]
                    : [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
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
                
                VStack(spacing: 8) {
                    Text("Goals")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                VStack(spacing: 20) {
                    WeeklyGoalCard(
                        hours: $weeklyGoalHours,
                        minutes: $weeklyGoalMinutes,
                        isBlocked: isBlocked,
                        hasGoal: $hasWeeklyGoal,
                        isEditing: $isEditingWeekly,
                        startDate: weeklyGoalStartDate,
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
                        onSave: {
                            saveMonthlyGoal()
                        }
                    )
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                VStack(spacing: 0) {
                    WhiteRoundedBottomPlain(isBlocked: isBlocked)
                    TabBar(selectedTab: $selectedTab)
                        .padding(.bottom, -50)
                }
            }
        }
        .preferredColorScheme(isBlocked ? .dark : .light)
        .onAppear {
            checkNotificationStatus()
            loadGoals()
            checkAndRecalculatePeriods()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkNotificationStatus()
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
        
        if hasWeeklyGoal {
            weeklyGoalHours = userDefaults.integer(forKey: "weekly_goal_hours")
            weeklyGoalMinutes = userDefaults.integer(forKey: "weekly_goal_minutes")
            let startDateTimestamp = userDefaults.double(forKey: "weekly_goal_start_date")
            if startDateTimestamp > 0 {
                weeklyGoalStartDate = Date(timeIntervalSince1970: startDateTimestamp)
            }
        }
        
        if hasMonthlyGoal {
            monthlyGoalHours = userDefaults.integer(forKey: "monthly_goal_hours")
            monthlyGoalMinutes = userDefaults.integer(forKey: "monthly_goal_minutes")
            let startDateTimestamp = userDefaults.double(forKey: "monthly_goal_start_date")
            if startDateTimestamp > 0 {
                monthlyGoalStartDate = Date(timeIntervalSince1970: startDateTimestamp)
            }
        }
    }
    
    private func saveWeeklyGoal() {
        let userDefaults = UserDefaults.standard
        let isNew = !hasWeeklyGoal
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        userDefaults.set(true, forKey: "weekly_goal_exists")
        userDefaults.set(weeklyGoalHours, forKey: "weekly_goal_hours")
        userDefaults.set(weeklyGoalMinutes, forKey: "weekly_goal_minutes")
        
        if let startDate = weeklyGoalStartDate {
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
        isEditingWeekly = false
        
        if isNew {
            print("✅ [Goals] Weekly goal created - \(weeklyGoalHours)h \(weeklyGoalMinutes)m")
        } else {
            print("✏️ [Goals] Weekly goal updated - \(weeklyGoalHours)h \(weeklyGoalMinutes)m")
        }
    }
    
    private func saveMonthlyGoal() {
        let userDefaults = UserDefaults.standard
        let isNew = !hasMonthlyGoal
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        userDefaults.set(true, forKey: "monthly_goal_exists")
        userDefaults.set(monthlyGoalHours, forKey: "monthly_goal_hours")
        userDefaults.set(monthlyGoalMinutes, forKey: "monthly_goal_minutes")
        
        if let startDate = monthlyGoalStartDate {
            let endDate = calendar.date(byAdding: .day, value: 30, to: startDate)!
            if Date() >= endDate {
                monthlyGoalStartDate = today
                userDefaults.set(today.timeIntervalSince1970, forKey: "monthly_goal_start_date")
                print("📅 [Goals] Monthly goal recalculated - new period: \(formatDate(today)) to \(formatDate(calendar.date(byAdding: .day, value: 30, to: today)!))")
            } else {
                userDefaults.set(startDate.timeIntervalSince1970, forKey: "monthly_goal_start_date")
            }
        } else {
            monthlyGoalStartDate = today
            userDefaults.set(today.timeIntervalSince1970, forKey: "monthly_goal_start_date")
        }
        
        hasMonthlyGoal = true
        isEditingMonthly = false
        
        if isNew {
            print("✅ [Goals] Monthly goal created - \(monthlyGoalHours)h \(monthlyGoalMinutes)m")
        } else {
            print("✏️ [Goals] Monthly goal updated - \(monthlyGoalHours)h \(monthlyGoalMinutes)m")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func checkAndRecalculatePeriods() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let userDefaults = UserDefaults.standard
        
        // Check weekly goal
        if hasWeeklyGoal, let startDate = weeklyGoalStartDate {
            let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
            if Date() >= endDate {
                weeklyGoalStartDate = today
                userDefaults.set(today.timeIntervalSince1970, forKey: "weekly_goal_start_date")
                print("📅 [Goals] Weekly goal period expired, recalculated - new period: \(formatDate(today)) to \(formatDate(calendar.date(byAdding: .day, value: 7, to: today)!))")
            }
        }
        
        // Check monthly goal
        if hasMonthlyGoal, let startDate = monthlyGoalStartDate {
            let endDate = calendar.date(byAdding: .day, value: 30, to: startDate)!
            if Date() >= endDate {
                monthlyGoalStartDate = today
                userDefaults.set(today.timeIntervalSince1970, forKey: "monthly_goal_start_date")
                print("📅 [Goals] Monthly goal period expired, recalculated - new period: \(formatDate(today)) to \(formatDate(calendar.date(byAdding: .day, value: 30, to: today)!))")
            }
        }
    }
}



struct TimeInputView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    let isBlocked: Bool
    let maxHours: Int
    
    init(hours: Binding<Int>, minutes: Binding<Int>, isBlocked: Bool, maxHours: Int = 999) {
        self._hours = hours
        self._minutes = minutes
        self.isBlocked = isBlocked
        self.maxHours = maxHours
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Hours")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if hours > 0 {
                                hours -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(hours == 0 ? (isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA")) : (isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8")))
                        }
                        .disabled(hours == 0)
                        
                        Text("\(hours)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                            .frame(minWidth: 60)
                        
                        Button(action: {
                            if hours < maxHours {
                                hours += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(hours >= maxHours ? (isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA")) : .blue)
                        }
                        .disabled(hours >= maxHours)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Text(":")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8"))
                    .padding(.top, 20)
                
                VStack(spacing: 8) {
                    Text("Minutes")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if minutes > 0 {
                                minutes -= 1
                            } else if hours > 0 {
                                hours -= 1
                                minutes = 59
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor((hours == 0 && minutes == 0) ? (isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA")) : (isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8")))
                        }
                        .disabled(hours == 0 && minutes == 0)
                        
                        Text(String(format: "%02d", minutes))
                            .font(.system(size: 32, weight: .bold))
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
                                .font(.system(size: 28))
                                .foregroundColor((hours >= maxHours && minutes >= 59) ? (isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA")) : .blue)
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
