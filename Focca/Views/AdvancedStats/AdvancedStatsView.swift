import SwiftUI
import UIKit

struct AdvancedStatsView: View {
    @Binding var selectedTab: Int
    let isBlocked: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var totalBlockedTime: TimeInterval = 0
    @State private var showTimeInDays: Bool = false
    @State private var currentStreak: Int = 0
    @State private var averageTimePerDay: TimeInterval = 0
    @State private var weeklyGoalsCompleted: Int = 0
    @State private var monthlyGoalsCompleted: Int = 0
    
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
                    .padding(.top, 0)
                    
                    Spacer()
                }
                
                // Título
                VStack(spacing: 4) {
                    Text("Advanced Statistics")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Conteúdo
                VStack(spacing: 12) {
                    // Card de tempo total bloqueado
                    VStack(spacing: 12) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                                
                                Text("Total Blocked Time")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                            }
                            
                            Spacer()
                            
                            // Botão para alternar entre horas/minutos e dias
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showTimeInDays.toggle()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: showTimeInDays ? "clock" : "calendar")
                                        .font(.system(size: 10, weight: .medium))
                                    Text(showTimeInDays ? "Hours" : "Days")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isBlocked ? Color(hex: "2C2C2E") : Color(hex: "F5F5F5"))
                                )
                            }
                        }
                        
                        VStack(spacing: 2) {
                            if showTimeInDays {
                                Text(formattedTotalTime)
                                    .font(.system(size: 28, weight: .light, design: .rounded))
                                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            } else {
                                TimeDisplayView(time: totalBlockedTime, isBlocked: isBlocked)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                            .shadow(color: Color.black.opacity(isBlocked ? 0.3 : 0.04), radius: 3, x: 0, y: 1)
                    )
                    .padding(.horizontal, 16)
                    
                    // Grid de cards menores
                    VStack(spacing: 10) {
                        // Primeira linha: Streak e Average
                        HStack(spacing: 10) {
                            StreakCard(streak: currentStreak, isBlocked: isBlocked)
                            AverageCard(averageTime: averageTimePerDay, isBlocked: isBlocked)
                        }
                        
                        // Segunda linha: Weekly e Monthly Goals
                        HStack(spacing: 10) {
                            WeeklyGoalsCard(completed: weeklyGoalsCompleted, isBlocked: isBlocked)
                            MonthlyGoalsCard(completed: monthlyGoalsCompleted, isBlocked: isBlocked)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    AdvancedStatsShareControl(configuration: shareConfiguration)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                }
                .padding(.bottom, 105)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, -90)
            
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
            loadTotalBlockedTime()
            loadGoalsCompleted()
            StatsAchievementManager.shared.markAchievementsAsViewed()
        }
    }
    
    private var formattedTotalTime: String {
        if showTimeInDays {
            let days = totalBlockedTime / (24 * 3600)
            if days < 1 {
                let hours = Int(totalBlockedTime) / 3600
                let minutes = (Int(totalBlockedTime) % 3600) / 60
                if hours > 0 {
                    return String(format: "%.2f days\n(%dh %dm)", days, hours, minutes)
                } else {
                    return String(format: "%.2f days\n(%dm)", days, minutes)
                }
            } else if days < 7 {
                let fullDays = Int(days)
                let remainingHours = Int((days - Double(fullDays)) * 24)
                if remainingHours > 0 {
                    return "\(fullDays) day\(fullDays == 1 ? "" : "s"), \(remainingHours) hour\(remainingHours == 1 ? "" : "s")"
                } else {
                    return "\(fullDays) day\(fullDays == 1 ? "" : "s")"
                }
            } else {
                let weeks = Int(days / 7)
                let remainingDays = Int(days.truncatingRemainder(dividingBy: 7))
                if remainingDays == 0 {
                    return "\(weeks) week\(weeks == 1 ? "" : "s")"
                } else {
                    return "\(weeks) week\(weeks == 1 ? "" : "s"), \(remainingDays) day\(remainingDays == 1 ? "" : "s")"
                }
            }
        } else {
            let hours = Int(totalBlockedTime) / 3600
            let minutes = (Int(totalBlockedTime) % 3600) / 60
            if hours > 0 {
                return String(format: "%dh %dm", hours, minutes)
            } else {
                return String(format: "%dm", minutes)
            }
        }
    }
    
    private func loadTotalBlockedTime() {
        let dailyTimes = TimerStorage.shared.getAllDailyTimes()
        totalBlockedTime = dailyTimes.reduce(0) { $0 + $1.time }
        averageTimePerDay = TimerStorage.shared.getAverageTime()
        currentStreak = calculateStreak(dailyTimes: dailyTimes)
    }
    
    private func loadGoalsCompleted() {
        let userDefaults = UserDefaults.standard
        weeklyGoalsCompleted = userDefaults.integer(forKey: "weekly_goals_completed")
        monthlyGoalsCompleted = userDefaults.integer(forKey: "monthly_goals_completed")
    }
    
    private var formattedAverageTime: String {
        let hours = Int(averageTimePerDay) / 3600
        let minutes = (Int(averageTimePerDay) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func calculateStreak(dailyTimes: [(date: Date, time: TimeInterval)]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let minTimePerDay: TimeInterval = 3600 // 1 hora
        
        guard !dailyTimes.isEmpty else { return 0 }
        
        // Cria um dicionário para acesso rápido por data
        var timeByDate: [Date: TimeInterval] = [:]
        for (date, time) in dailyTimes {
            let dayStart = calendar.startOfDay(for: date)
            // Se já existe uma entrada para este dia, usa o maior valor
            if let existingTime = timeByDate[dayStart] {
                timeByDate[dayStart] = max(existingTime, time)
            } else {
                timeByDate[dayStart] = time
            }
        }
        
        // O streak SEMPRE começa de hoje
        // Se hoje não tem pelo menos 1h, o streak é 0 (quebrado)
        let todayTime = timeByDate[today] ?? 0
        guard todayTime >= minTimePerDay else { return 0 }
        
        // Conta os dias consecutivos a partir de hoje, indo para trás
        // O streak mínimo é 1 (se hoje tem pelo menos 1h, já conta como 1 dia)
        var streak = 1 // Já contamos hoje
        var currentDate = today
        
        while true {
            if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                let previousDayStart = calendar.startOfDay(for: previousDay)
                if let time = timeByDate[previousDayStart], time >= minTimePerDay {
                    streak += 1
                    currentDate = previousDayStart
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        // Garante que o streak mínimo seja 1 se hoje tem pelo menos 1h
        return max(1, streak)
    }
    
    private var shareConfiguration: AdvancedStatsShareConfiguration {
        AdvancedStatsShareConfiguration(
            isBlocked: isBlocked,
            totalTimeText: formattedTotalTime,
            averageTimeText: formattedAverageTime,
            streak: currentStreak,
            weeklyGoals: weeklyGoalsCompleted,
            monthlyGoals: monthlyGoalsCompleted
        )
    }
}

private struct TimeDisplayView: View {
    let time: TimeInterval
    let isBlocked: Bool
    
    var body: some View {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        HStack(spacing: 0) {
            if hours > 0 {
                Text("\(hours)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                Text("h")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                Text(" \(minutes)")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                Text("m")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
            } else {
                Text("\(minutes)")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                Text("m")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
            }
        }
    }
}

#Preview {
    AdvancedStatsView(selectedTab: .constant(1), isBlocked: false)
}
