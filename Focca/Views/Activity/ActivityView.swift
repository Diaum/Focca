import SwiftUI

struct ActivityView: View {
    @Binding var selectedTab: Int
    let isBlocked: Bool
    @State private var showModeSheet = false
    @State private var showEditMode = false
    @State private var modeToEdit: String?
    @State private var showCreateMode = false
    @State private var showAdvancedStats = false
    @State private var showGoals = false
    @State private var todayTime: String = "0h 0m"
    @State private var averageTime: String = "0h 0m"
    @State private var dailyCards: [(date: Date, time: TimeInterval)] = []
    @State private var expandedCardDate: Date? = nil
    let initialDailyCards: [(date: Date, time: TimeInterval)]?
    
    init(selectedTab: Binding<Int>, isBlocked: Bool = false, initialDailyCards: [(date: Date, time: TimeInterval)]? = nil) {
        self._selectedTab = selectedTab
        self.isBlocked = isBlocked
        self.initialDailyCards = initialDailyCards
    }
        
    var body: some View {
        ZStack {
            (isBlocked
                ? Color(hex: "0A0A0A")
                : Color(hex: "EDE7E6"))
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Button(action: {
                            showGoals = true
                        }) {
                            Image(systemName: "target")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isBlocked ? Color(hex: "D1D1D6") : Color(hex: "3C3C43").opacity(0.6))
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(isBlocked ? Color(hex: "1E1E1F") : Color.white)
                                        .shadow(color: Color.black.opacity(isBlocked ? 0.4 : 0.04), radius: 6, x: 0, y: 3)
                                )
                        }
                        
                        Button(action: {
                            showAdvancedStats = true
                        }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isBlocked ? Color(hex: "D1D1D6") : Color(hex: "3C3C43").opacity(0.6))
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(isBlocked ? Color(hex: "1E1E1F") : Color.white)
                                        .shadow(color: Color.black.opacity(isBlocked ? 0.4 : 0.04), radius: 6, x: 0, y: 3)
                                )
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                
                Spacer(minLength: 20)
                
                HStack(spacing: 80) {
                    VStack(spacing: 4) {
                        Text("Hoje")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        
                        HStack(spacing: 4) {
                            Text(todayHoursText)
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                            Text(todayMinutesText)
                                .font(.system(size: 28, weight: .light, design: .rounded))
                                .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text("Média/dia")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        
                        HStack(spacing: 4) {
                            Text(averageHoursText)
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                            Text(averageMinutesText)
                                .font(.system(size: 28, weight: .light, design: .rounded))
                                .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                        }
                    }
                }
                .padding(.top, 0)
                .padding(.bottom, 60)
                
                if dailyCards.isEmpty {
                    Text("As atividades aparecem após o seu primeiro dia usando o Focca.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "9E9EA3"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 40)

                } else {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            cardGrid
                                .padding(.top, 0)
                                .padding(.bottom, 120)
                        }
                        .onChange(of: expandedCardDate) { newValue in
                            if let expandedDate = newValue {
                                if let card = dailyCards.first(where: { $0.date == expandedDate }),
                                   card.time > 0 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            proxy.scrollTo(expandedDate, anchor: .top)
                                        }
                                    }
                                } else {
                                    expandedCardDate = nil
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 60)

            VStack(spacing: 0) {
                Spacer()
                WhiteRoundedBottomPlain(isBlocked: isBlocked)
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -48)
            }
            .zIndex(1)
            
        }
        .sheet(isPresented: $showModeSheet) {
            ModeSelectionSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .sheet(item: Binding(
            get: { modeToEdit },
            set: { modeToEdit = $0 }
        )) { modeName in
            EditModeView(modeName: modeName)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .sheet(isPresented: $showCreateMode) {
            CreateModeView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenEditMode"))) { notification in
            if let modeName = notification.object as? String {
                modeToEdit = modeName
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenCreateMode"))) { _ in
            showCreateMode = true
        }
        .fullScreenCover(isPresented: $showAdvancedStats) {
            AdvancedStatsView(selectedTab: $selectedTab, isBlocked: isBlocked)
        }
        .fullScreenCover(isPresented: $showGoals) {
            GoalsView(selectedTab: $selectedTab, isBlocked: isBlocked)
        }
        .preferredColorScheme(isBlocked ? .dark : .light)
        .onAppear {
            if let injected = initialDailyCards {
                dailyCards = injected
            } else {
                loadActivityData()
            }
            updateTodayTime()
            StatsAchievementManager.shared.updateAchievements()
            expandedCardDate = nil
            
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                DispatchQueue.main.async {
                    self.updateTodayTime()
                }
            }
        }
        .onChange(of: selectedTab) { _ in
            expandedCardDate = nil
        }
        .onDisappear {
            expandedCardDate = nil
        }
    }
    
    private var todayHoursText: String {
        let parts = todayTime.components(separatedBy: " ")
        return parts.first ?? "0h"
    }
    
    private var todayMinutesText: String {
        let parts = todayTime.components(separatedBy: " ")
        guard parts.count > 1 else { return "00m" }
        return parts[1]
    }
    
    private var averageHoursText: String {
        let parts = averageTime.components(separatedBy: " ")
        return parts.first ?? "0h"
    }
    
    private var averageMinutesText: String {
        let parts = averageTime.components(separatedBy: " ")
        guard parts.count > 1 else { return "00m" }
        return parts[1]
    }
    
    private func loadActivityData() {
        // Carrega cache instantaneamente (síncrono)
        let cachedCards = TimerStorage.shared.getAllDailyTimesSync()
        dailyCards = cachedCards
        
        let cachedAvgTime = TimerStorage.shared.getAverageTimeSync()
        let hours = Int(cachedAvgTime) / 3600
        let minutes = (Int(cachedAvgTime) % 3600) / 60
        averageTime = String(format: "%dh %dm", hours, minutes)
        
        // Em paralelo, busca do banco e atualiza
        Task {
            let cards = await TimerStorage.shared.getAllDailyTimes()
            await MainActor.run {
                // Só atualiza se houver diferença (evita flicker)
                if cards.count != dailyCards.count || 
                   !cards.elementsEqual(dailyCards, by: { $0.date == $1.date && abs($0.time - $1.time) < 1.0 }) {
                    dailyCards = cards
                }
            }
            
            let avgTime = await TimerStorage.shared.getAverageTime()
            let hours = Int(avgTime) / 3600
            let minutes = (Int(avgTime) % 3600) / 60
            await MainActor.run {
                averageTime = String(format: "%dh %dm", hours, minutes)
            }
        }
    }
    
    private var compactCards: [(date: Date, time: TimeInterval)] {
        dailyCards.filter { expandedCardDate == nil || $0.date != expandedCardDate }
    }
    
    @ViewBuilder
    private var cardGrid: some View {
        VStack(spacing: 10) {
            if let expandedDate = expandedCardDate,
               let expandedCard = dailyCards.first(where: { $0.date == expandedDate }),
               expandedCard.time > 0 {
                DailyCard(
                    date: expandedCard.date,
                    time: expandedCard.time,
                    isBlocked: isBlocked,
                    isExpanded: true,
                    onTap: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.2)) {
                            expandedCardDate = nil
                        }
                    }
                )
                .id(expandedCard.date)
                .padding(.horizontal, 20)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                        ForEach(compactCards, id: \.date) { card in
                    if card.time > 0 {
                        DailyCard(
                            date: card.date,
                            time: card.time,
                            isBlocked: isBlocked,
                            isExpanded: false,
                            onTap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.2)) {
                                    expandedCardDate = card.date
                                }
                            }
                        )
                        .id(card.date)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                    } else {
                        DailyCard(
                            date: card.date,
                            time: card.time,
                            isBlocked: isBlocked,
                            isExpanded: false,
                            onTap: nil
                        )
                        .id(card.date)
                        .allowsHitTesting(false)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.2), value: expandedCardDate)
    }
    
    private func updateTodayTime() {
        let totalTime = TimerStorage.shared.getTodayTime()
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        todayTime = String(format: "%dh %dm", hours, minutes)
    }
}

#Preview {
    // Gera 10 cards de dias anteriores para visualização no Preview
    let calendar = Calendar.current
    let samples: [(date: Date, time: TimeInterval)] = (0..<15).compactMap { offset in
        if let date = calendar.date(byAdding: .day, value: -offset, to: Date()) {
            // Ex.: 45min, 60min, 75min, 90min, 105min
            let mins = 45 + offset * 15
            return (date: date, time: TimeInterval(mins * 60))
        }
        return nil
    }
    return ActivityView(selectedTab: .constant(2), initialDailyCards: samples)
}


