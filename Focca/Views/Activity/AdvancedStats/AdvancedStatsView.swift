import SwiftUI

struct AdvancedStatsView: View {
    @Binding var selectedTab: Int
    let isBlocked: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var totalBlockedTime: TimeInterval = 0
    @State private var showTimeInDays: Bool = false
    @State private var currentStreak: Int = 0
    @State private var averageTimePerDay: TimeInterval = 0
    
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
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                // Título
                VStack(spacing: 8) {
                    Text("Advanced Statistics")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
                
                // Conteúdo
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Card de tempo total bloqueado
                        VStack(spacing: 16) {
                            HStack {
                                Text("Total Blocked Time")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                                
                                Spacer()
                                
                                // Botão para alternar entre horas/minutos e dias
                                Button(action: {
                                    withAnimation {
                                        showTimeInDays.toggle()
                                    }
                                }) {
                                    Text(showTimeInDays ? "Hours" : "Days")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                                }
                            }
                            
                            VStack(spacing: 12) {
                                Text(formattedTotalTime)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                                .shadow(color: Color.black.opacity(isBlocked ? 0.3 : 0.04), radius: 3, x: 0, y: 1)
                        )
                        .padding(.horizontal, 16)
                        
                        // Cards de streak e média lado a lado
                        HStack(spacing: 12) {
                            StreakCard(streak: currentStreak, isBlocked: isBlocked)
                            AverageCard(averageTime: averageTimePerDay, isBlocked: isBlocked)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 0)
                    .padding(.bottom, 250)
                }
                
                Spacer()
                
                // Bottom arredondado e TabBar
                VStack(spacing: 0) {
                    WhiteRoundedBottomPlain(isBlocked: isBlocked)
                    TabBar(selectedTab: $selectedTab)
                        .padding(.bottom, -50)
                }
            }
        }
        .preferredColorScheme(isBlocked ? .dark : .light)
        .onAppear {
            loadTotalBlockedTime()
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
        
        return streak
    }
}

#Preview {
    AdvancedStatsView(selectedTab: .constant(1), isBlocked: false)
}

