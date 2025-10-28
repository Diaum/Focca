import Foundation

class TimerStorage {
    static let shared = TimerStorage()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    func initializeFirstLaunch() {
        if userDefaults.object(forKey: "first_launch_date") == nil {
            let today = Calendar.current.startOfDay(for: Date())
            userDefaults.set(today, forKey: "first_launch_date")
        }
    }
    
    func getDailyTime(for date: Date) -> TimeInterval {
        let dateKey = formatDate(date)
        return userDefaults.double(forKey: "daily_time_\(dateKey)")
    }
    
    func addDailyTime(_ timeInterval: TimeInterval, for date: Date) {
        let dateKey = formatDate(date)
        let currentTime = getDailyTime(for: date)
        let newTime = currentTime + timeInterval
        userDefaults.set(newTime, forKey: "daily_time_\(dateKey)")
    }
    
    func getTodayTime() -> TimeInterval {
        return getDailyTime(for: Date())
    }
    
    func splitOvernightTime(from startDate: Date, to endDate: Date) {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        
        if startDay < endDay {
            let startDayEnd = calendar.date(byAdding: .day, value: 1, to: startDay)!
            let timeInStartDay = startDayEnd.timeIntervalSince(startDate)
            let timeInEndDay = endDate.timeIntervalSince(endDay)
            
            addDailyTime(timeInStartDay, for: startDate)
            addDailyTime(timeInEndDay, for: endDate)
        } else {
            let totalTime = endDate.timeIntervalSince(startDate)
            addDailyTime(totalTime, for: startDate)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

