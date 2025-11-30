import SwiftUI
import UIKit
import Combine

struct MonthlyGoalCard: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    let isBlocked: Bool
    @Binding var hasGoal: Bool
    @Binding var isEditing: Bool
    let startDate: Date?
    let isOtherGoalEditing: Bool
    let onEditRequest: () -> Void
    let onSave: () -> Void
    
    @State private var currentProgress: TimeInterval = 0
    @State private var goalTime: TimeInterval = 0
    
    private var periodText: String? {
        guard let start = startDate else { return nil }
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: start))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: monthStart)) - \(formatter.string(from: monthEnd))"
    }
    
    private var progressPercentage: Double {
        guard goalTime > 0 else { return 0 }
        return currentProgress / goalTime
    }
    
    private var hasExtraTime: Bool {
        return currentProgress > goalTime && goalTime > 0
    }
    
    private var extraTime: TimeInterval {
        return max(0, currentProgress - goalTime)
    }
    
    private var extraPercentage: Double {
        guard goalTime > 0 else { return 0 }
        return max(0, (currentProgress - goalTime) / goalTime)
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date()).capitalized
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    
                    Text("Metas de " + monthName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    
                    Spacer()
                    
                    if let period = periodText {
                        Text(period)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    }
                }
                
                Text("O tempo mínimo mensal que você idealmente deseja ficar longe dos seus apps.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if hasGoal && !isEditing {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Meta Atual")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                            
                            GoalTimeDisplayView(hours: hours, minutes: minutes, isBlocked: isBlocked)
                        }
                        
                        Spacer()
                        
                                VStack(alignment: .trailing, spacing: 4) {
                                    Button(action: {
                                        onEditRequest()
                                    }) {
                                        Text("Excluir")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(isOtherGoalEditing ? (isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8")) : (isBlocked ? .white : Color(hex: "1C1C1E")))
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(isOtherGoalEditing ? (isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA")) : (isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA")))
                                            .cornerRadius(10)
                                    }
                                    .disabled(isOtherGoalEditing)
                                    
                                    if isOtherGoalEditing {
                                        Text("Termine de editar a outra meta primeiro")
                                            .font(.system(size: 10, weight: .regular))
                                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                    }
                    
                    // Progress Bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progresso")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                            
                            Spacer()
                            
                            Text("\(Int(progressPercentage * 100))%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA"))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isBlocked ? Color.white : Color.black)
                                    .frame(width: geometry.size.width * min(progressPercentage, 1.0), height: 8)
                                
                                if hasExtraTime {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.green)
                                        .frame(width: min(geometry.size.width * extraPercentage, geometry.size.width * 0.3), height: 8)
                                        .offset(x: geometry.size.width)
                                }
                            }
                            .clipped()
                        }
                        .frame(height: 8)
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
                    Text("Criar Meta")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isBlocked ? Color(hex: "2C2C2E") : Color(hex: "1C1C1E"))
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isBlocked ? Color(hex: "1C1C1C") : Color(hex: "e4e0e0"))
                .shadow(color: Color.black.opacity(isBlocked ? 0.3 : 0.04), radius: 3, x: 0, y: 1)
        )
        .onAppear {
            // Update immediately when card appears
            DispatchQueue.main.async {
                self.updateProgress()
            }
        }
        .onChange(of: hasGoal) { _ in
            DispatchQueue.main.async {
                self.updateProgress()
            }
        }
        .onChange(of: startDate) { _ in
            DispatchQueue.main.async {
                self.updateProgress()
            }
        }
        .onChange(of: hours) { _ in
            DispatchQueue.main.async {
                self.updateProgress()
            }
        }
        .onChange(of: minutes) { _ in
            DispatchQueue.main.async {
                self.updateProgress()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateProgress()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            updateProgress()
            // Check progress notifications periodically
            if hasGoal, let start = startDate {
                Task {
                    await GoalsNotificationManager.shared.checkAndSendProgressNotifications(
                        goalType: .monthly,
                        hours: hours,
                        minutes: minutes,
                        startDate: start
                    )
                    // Check smart notification every 5 minutes
                    let now = Date()
                    let calendar = Calendar.current
                    let currentMinutes = calendar.component(.minute, from: now)
                    if currentMinutes % 5 == 0 {
                        await GoalsNotificationManager.shared.checkAndSendSmartNotification(
                            goalType: .monthly,
                            hours: hours,
                            minutes: minutes,
                            startDate: start
                        )
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateMonthlyGoalProgress"))) { _ in
            DispatchQueue.main.async {
                self.updateProgress()
            }
        }
    }
    
    private func updateProgress() {
        // Don't calculate progress if goals are disabled
        guard GoalsManager.shared.areGoalsEnabled else {
            currentProgress = 0
            goalTime = 0
            return
        }
        
        guard let start = startDate else {
            currentProgress = 0
            goalTime = 0
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get the month start and end for the month of the start date
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: start))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        let monthEndDay = calendar.startOfDay(for: monthEnd)
        
        // Calculate goal time in seconds
        goalTime = TimeInterval(hours * 3600 + minutes * 60)
        
        // Calculate current progress by summing daily times in the month
        var totalTime: TimeInterval = 0
        var currentDate = monthStart
        var dayCount = 0
        
        // Include today if we're still within the month
        let maxDate = min(monthEndDay, today)
        
        while currentDate <= maxDate {
            let dailyTime = TimerStorage.shared.getDailyTime(for: currentDate)
            totalTime += dailyTime
            
            dayCount += 1
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        currentProgress = totalTime
        
        // Check and send progress notifications
        Task {
            // Reuse monthStart from above
            await GoalsNotificationManager.shared.checkAndSendProgressNotifications(
                goalType: .monthly,
                hours: hours,
                minutes: minutes,
                startDate: monthStart
            )
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

private struct GoalTimeDisplayView: View {
    let hours: Int
    let minutes: Int
    let isBlocked: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            if hours > 0 {
                Text("\(hours)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                Text("h")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                Text(" \(String(format: "%02d", minutes))")
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                Text("m")
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
            } else {
                Text("\(minutes)")
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                Text("m")
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
            }
        }
    }
}

