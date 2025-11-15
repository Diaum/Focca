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
    let onSave: () -> Void
    
    @State private var currentProgress: TimeInterval = 0
    @State private var goalTime: TimeInterval = 0
    
    private var periodText: String? {
        guard let start = startDate else { return nil }
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 30, to: start)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: endDate))"
    }
    
    private var progressPercentage: Double {
        guard goalTime > 0 else { return 0 }
        return min(currentProgress / goalTime, 1.0)
    }
    
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
                    
                    if let period = periodText {
                        Text(period)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    }
                }
                
                Text("The minimum monthly time you ideally want to stay away from your apps.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if hasGoal && !isEditing {
                VStack(alignment: .leading, spacing: 16) {
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
                                .background(isBlocked ? Color(hex: "2C2C2E") : Color(hex: "1C1C1E"))
                                .cornerRadius(10)
                        }
                    }
                    
                    // Progress Bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                            
                            Spacer()
                            
                            Text("\(formatTimeInterval(currentProgress)) / \(formatTime(hours: hours, minutes: minutes))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA"))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.purple)
                                    .frame(width: geometry.size.width * progressPercentage, height: 8)
                            }
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
                    Text(hasGoal ? "Update Goal" : "Save Goal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isBlocked ? Color(hex: "2C2C2E") : Color(hex: "1C1C1E"))
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
        .onAppear {
            updateProgress()
        }
        .onChange(of: hasGoal) { _ in
            updateProgress()
        }
        .onChange(of: startDate) { _ in
            updateProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateProgress()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            updateProgress()
        }
    }
    
    private func updateProgress() {
        guard let start = startDate else {
            currentProgress = 0
            goalTime = 0
            return
        }
        
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 30, to: start)!
        let today = calendar.startOfDay(for: Date())
        
        // Calculate goal time in seconds
        goalTime = TimeInterval(hours * 3600 + minutes * 60)
        
        // Calculate current progress by summing daily times in the period
        var totalTime: TimeInterval = 0
        var currentDate = start
        
        while currentDate <= endDate && currentDate <= today {
            let dailyTime = TimerStorage.shared.getDailyTime(for: currentDate)
            totalTime += dailyTime
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        currentProgress = totalTime
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
}

