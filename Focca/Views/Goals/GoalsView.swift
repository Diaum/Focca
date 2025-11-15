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
                .padding(.bottom, 30)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        WeeklyGoalCard(
                            hours: $weeklyGoalHours,
                            minutes: $weeklyGoalMinutes,
                            isBlocked: isBlocked,
                            hasGoal: $hasWeeklyGoal,
                            isEditing: $isEditingWeekly,
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
                            onSave: {
                                saveMonthlyGoal()
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, 300)
                }
                
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
        }
        
        if hasMonthlyGoal {
            monthlyGoalHours = userDefaults.integer(forKey: "monthly_goal_hours")
            monthlyGoalMinutes = userDefaults.integer(forKey: "monthly_goal_minutes")
        }
    }
    
    private func saveWeeklyGoal() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "weekly_goal_exists")
        userDefaults.set(weeklyGoalHours, forKey: "weekly_goal_hours")
        userDefaults.set(weeklyGoalMinutes, forKey: "weekly_goal_minutes")
        hasWeeklyGoal = true
        isEditingWeekly = false
    }
    
    private func saveMonthlyGoal() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "monthly_goal_exists")
        userDefaults.set(monthlyGoalHours, forKey: "monthly_goal_hours")
        userDefaults.set(monthlyGoalMinutes, forKey: "monthly_goal_minutes")
        hasMonthlyGoal = true
        isEditingMonthly = false
    }
}

struct WeeklyGoalCard: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    let isBlocked: Bool
    @Binding var hasGoal: Bool
    @Binding var isEditing: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                    
                    Text("Weekly Goal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    
                    Spacer()
                }
                
                Text("The minimum weekly time you ideally want to stay away from your apps.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if hasGoal && !isEditing {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Goal")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                        
                        Text(formatTime(hours: hours, minutes: minutes))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isEditing = true
                    }) {
                        Text("Edit")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            } else {
                TimeInputView(
                    hours: $hours,
                    minutes: $minutes,
                    isBlocked: isBlocked,
                    maxHours: 167
                )
                
                Button(action: onSave) {
                    Text(hasGoal ? "Update Goal" : "Save Goal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                .shadow(color: Color.black.opacity(isBlocked ? 0.3 : 0.04), radius: 3, x: 0, y: 1)
        )
    }
}

struct MonthlyGoalCard: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    let isBlocked: Bool
    @Binding var hasGoal: Bool
    @Binding var isEditing: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18))
                        .foregroundColor(.purple)
                    
                    Text("Monthly Goal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    
                    Spacer()
                }
                
                Text("The minimum monthly time you ideally want to stay away from your apps.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if hasGoal && !isEditing {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Goal")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                        
                        Text(formatTime(hours: hours, minutes: minutes))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isEditing = true
                    }) {
                        Text("Edit")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            } else {
                TimeInputView(
                    hours: $hours,
                    minutes: $minutes,
                    isBlocked: isBlocked,
                    maxHours: 744
                )
                
                Button(action: onSave) {
                    Text(hasGoal ? "Update Goal" : "Save Goal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                .shadow(color: Color.black.opacity(isBlocked ? 0.3 : 0.04), radius: 3, x: 0, y: 1)
        )
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
