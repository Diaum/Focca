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
    
    private var averageTime: TimeInterval {
        TimerStorage.shared.getAverageTime()
    }
    
    private var averageHours: Int {
        Int(averageTime) / 3600
    }
    
    private var averageMinutes: Int {
        (Int(averageTime) % 3600) / 60
    }
    
    private var percentageBelowAverage: Int? {
        guard averageTime > 0 else { return nil }
        let diff = averageTime - time
        let percentage = Int((diff / averageTime) * 100)
        return percentage > 0 ? percentage : nil
    }
    
    private var previousDayTime: TimeInterval {
        let calendar = Calendar.current
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: date) {
            return AppBlockingTracker.shared.getTotalBlockingTime(for: previousDay)
        }
        return 0
    }
    
    private var weekAverageInfo: (average: TimeInterval, startDate: Date?, endDate: Date?) {
        let calendar = Calendar.current
        let allDailyTimes = TimerStorage.shared.getAllDailyTimes()
        
        guard !allDailyTimes.isEmpty else { return (0, nil, nil) }
        
        let dateStart = calendar.startOfDay(for: date)
        let weekStart = calendar.date(byAdding: .day, value: -7, to: dateStart) ?? dateStart
        
        let weekDays = allDailyTimes.filter { dailyTime in
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
    
    private var weekDateRange: String? {
        let info = weekAverageInfo
        guard let start = info.startDate, let end = info.endDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startStr = formatter.string(from: start).lowercased()
        let endStr = formatter.string(from: end).lowercased()
        
        return "\(startStr) a \(endStr)"
    }
    
    private var comparisonInfo: (text: String, color: Color)? {
        if previousDayTime > 0 {
            let diff = time - previousDayTime
            let percentage = Int((diff / previousDayTime) * 100)
            
            if percentage > 0 {
                return ("\(percentage)% superior a ontem", Color(hex: "34C759"))
            } else if percentage < 0 {
                return ("\(abs(percentage))% inferior a ontem", Color(hex: "FF3B30"))
            } else {
                return ("Igual a ontem", isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
            }
        } else if weekAverageTime > 0 {
            let diff = time - weekAverageTime
            let percentage = Int((diff / weekAverageTime) * 100)
            
            let weekRange = weekDateRange ?? ""
            let rangeText = weekRange.isEmpty ? "" : " (\(weekRange))"
            
            if percentage > 0 {
                return ("\(percentage)% superior à média da semana\(rangeText)", Color(hex: "34C759"))
            } else if percentage < 0 {
                return ("\(abs(percentage))% inferior à média da semana\(rangeText)", Color(hex: "FF3B30"))
            } else {
                return ("Igual à média da semana\(rangeText)", isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
            }
        } else {
            return nil
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
        HStack(alignment: .top, spacing: 16) {
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
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                if averageTime > 0 {
                    if let percentage = percentageBelowAverage {
                        Text("\(percentage)% abaixo da média")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "FF3B30"))
                    }
                    
                    Text("Média: \(averageHours)h \(String(format: "%02dm", averageMinutes))")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                }
                
                if let comparison = comparisonInfo {
                    Text(comparison.text)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(comparison.color)
                        .multilineTextAlignment(.trailing)
                } else {
                    Text("Ainda não há dados de comparativo")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                        .multilineTextAlignment(.trailing)
                }
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

