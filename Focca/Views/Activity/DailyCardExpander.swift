import SwiftUI

struct DailyCardExpander: View {
    let date: Date
    let time: TimeInterval
    let isBlocked: Bool
    
    private var isValid: Bool {
        time > 0
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date).lowercased()
    }
    
    private var hours: Int {
        Int(time) / 3600
    }
    
    private var minutes: Int {
        (Int(time) % 3600) / 60
    }
    
    private var allDailyTimes: [(date: Date, time: TimeInterval)] {
        TimerStorage.shared.getAllDailyTimes()
    }
    
    private var dailyAverageTime: TimeInterval {
        TimerStorage.shared.getAverageTime()
    }
    
    private var weekAverageInfo: (average: TimeInterval, startDate: Date?, endDate: Date?) {
        let calendar = Calendar.current
        let allTimes = allDailyTimes
        
        guard allTimes.count > 1 else { return (0, nil, nil) }
        
        let dateStart = calendar.startOfDay(for: date)
        let weekStart = calendar.date(byAdding: .day, value: -7, to: dateStart) ?? dateStart
        
        let weekDays = allTimes.filter { dailyTime in
            let dailyDate = calendar.startOfDay(for: dailyTime.date)
            return dailyDate >= weekStart && dailyDate < dateStart && dailyTime.time > 0
        }
        
        guard !weekDays.isEmpty else { return (0, nil, nil) }
        
        let totalTime = weekDays.reduce(0) { $0 + $1.time }
        let average = totalTime / Double(weekDays.count)
        
        let sortedWeekDays = weekDays.sorted { $0.date < $1.date }
        let startDate = sortedWeekDays.first?.date
        let endDate = sortedWeekDays.last?.date
        
        return (average, startDate, endDate)
    }
    
    private var weekAverageTime: TimeInterval {
        weekAverageInfo.average
    }
    
    private var hasEnoughData: Bool {
        allDailyTimes.count > 1
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return "\(hours)h\(String(format: "%02dm", minutes))"
    }
    
    private var comparisonText: String? {
        guard hasEnoughData else {
            return "Não tem estatísticas para comparação"
        }
        
        let hasDailyAverage = dailyAverageTime > 0
        let hasWeeklyAverage = weekAverageTime > 0
        
        if !hasDailyAverage && !hasWeeklyAverage {
            return "Não tem estatísticas para comparação"
        }
        
        var comparisons: [(text: String, type: String)] = []
        
        if hasDailyAverage {
            let diff = time - dailyAverageTime
            let percentage = abs(Int((diff / dailyAverageTime) * 100))
            let averageText = formatTime(dailyAverageTime)
            
            if diff > 0 {
                comparisons.append(("\(percentage)% acima da sua média diária (\(averageText))", "daily"))
            } else if diff < 0 {
                comparisons.append(("\(percentage)% abaixo da sua média diária (\(averageText))", "daily"))
            } else {
                comparisons.append(("O mesmo da sua média diária (\(averageText))", "daily"))
            }
        }
        
        if hasWeeklyAverage {
            let diff = time - weekAverageTime
            let percentage = abs(Int((diff / weekAverageTime) * 100))
            let averageText = formatTime(weekAverageTime)
            
            if diff > 0 {
                comparisons.append(("\(percentage)% acima da sua média semanal (\(averageText))", "weekly"))
            } else if diff < 0 {
                comparisons.append(("\(percentage)% abaixo da sua média semanal (\(averageText))", "weekly"))
            } else {
                comparisons.append(("O mesmo da sua média semanal (\(averageText))", "weekly"))
            }
        }
        
        guard !comparisons.isEmpty else {
            return "Não tem estatísticas para comparação"
        }
        
        if comparisons.count == 1 {
            return comparisons[0].text
        }
        
        let randomIndex = Int.random(in: 0..<comparisons.count)
        return comparisons[randomIndex].text
    }
    
    private var comparisonColor: Color {
        guard let text = comparisonText else {
            return isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93")
        }
        
        if text.contains("acima") {
            return Color(hex: "34C759")
        } else if text.contains("abaixo") {
            return Color(hex: "FF3B30")
        } else if text.contains("O mesmo") {
            return isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93")
        } else {
            return isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93")
        }
    }
    
    private var cardBackgroundColor: Color {
        if isBlocked {
            return Color(hex: "1C1C1C")
        } else {
            return Color.white
        }
    }
    
    private var timeTextColor: Color {
        isBlocked ? .white : Color(hex: "1C1C1E")
    }
    
    var body: some View {
        Group {
            if isValid {
                expandedContent
            } else {
                EmptyView()
            }
        }
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(formattedDate)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8A8A8E"))
                    
                    HStack(spacing: 4) {
                        Text("\(hours)h")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(timeTextColor)
                        Text(String(format: "%02dm", minutes))
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(timeTextColor)
                    }
                    
                    if let comparison = comparisonText {
                        Text(comparison)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(comparisonColor)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                Button(action: {
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isBlocked ? Color(hex: "2C2C2E") : Color(hex: "F5F5F5"))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: isBlocked ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
