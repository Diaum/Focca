import SwiftUI

struct ActivityView: View {
    @Binding var selectedTab: Int
    let isBlocked: Bool
    @State private var showModeSheet = false
    @State private var showEditMode = false
    @State private var modeToEdit: String?
    @State private var showCreateMode = false
    @State private var showDailyDetail = false
    @State private var showAdvancedStats = false
    @State private var showGoals = false
    @State private var selectedDate: Date?
    @State private var selectedTime: TimeInterval = 0
    @State private var todayTime: String = "0h 0m"
    @State private var averageTime: String = "0h 0m"
    @State private var dailyCards: [(date: Date, time: TimeInterval)] = []
    @State private var lastLoggedAppCount: Int = -1
    let initialDailyCards: [(date: Date, time: TimeInterval)]?
    
    init(selectedTab: Binding<Int>, isBlocked: Bool = false, initialDailyCards: [(date: Date, time: TimeInterval)]? = nil) {
        self._selectedTab = selectedTab
        self.isBlocked = isBlocked
        self.initialDailyCards = initialDailyCards
    }
        
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
                        Text("Today")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8A8A8E"))
                        
                        Text(todayTime)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    }
                    
                    VStack(spacing: 4) {
                        Text("Average")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8A8A8E"))
                        
                        Text(averageTime)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    }
                }
                .padding(.top, 0)
                .padding(.bottom, 60)
                
                if dailyCards.isEmpty {
                    Text("Activities will appear after your first day using Brick")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "9E9EA3"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 40)

                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ], spacing: 10) {
                            ForEach(dailyCards, id: \.date) { card in
                                DailyCard(
                                    date: card.date,
                                    time: card.time,
                                    isBlocked: isBlocked,
                                    onTap: {
                                        selectedDate = card.date
                                        selectedTime = card.time
                                        showDailyDetail = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 0)
                        .padding(.bottom, 250)
                    }
                }
            }
            .padding(.bottom, 105)

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
        .fullScreenCover(isPresented: $showDailyDetail) {
            Group {
                if let date = selectedDate {
                    DailyDetailView(date: date, totalTime: selectedTime, isBlocked: isBlocked, selectedTab: $selectedTab)
                        .onAppear {
                            print("✅ [ActivityView] DailyDetailView apareceu - date: \(date), time: \(selectedTime)")
                        }
                        .onDisappear {
                            selectedDate = nil
                            selectedTime = 0
                        }
                } else {
                    VStack {
                        Text("Erro: selectedDate é nil")
                            .foregroundColor(.red)
                            .padding()
                        Text("showDailyDetail: \(showDailyDetail ? "true" : "false")")
                            .foregroundColor(.red)
                            .padding()
                    }
                    .background(Color.white)
                    .onAppear {
                        print("⚠️ [ActivityView] Fallback apareceu - selectedDate é nil, showDailyDetail: \(showDailyDetail)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if selectedDate == nil {
                                print("❌ [ActivityView] Fechando fullScreenCover porque selectedDate é nil")
                                showDailyDetail = false
                            }
                        }
                    }
                }
            }
            .onAppear {
                print("📱 [ActivityView] fullScreenCover apareceu - showDailyDetail: \(showDailyDetail), selectedDate: \(selectedDate != nil ? "definido" : "nil")")
            }
        }
        .onChange(of: showDailyDetail) { newValue in
            print("🔄 [ActivityView] showDailyDetail mudou para: \(newValue)")
        }
        .onChange(of: selectedDate) { newValue in
            print("🔄 [ActivityView] selectedDate mudou para: \(newValue?.description ?? "nil")")
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
            
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                DispatchQueue.main.async {
                    self.updateTodayTime()
                }
            }
        }
    }
    
    private func loadActivityData() {
        dailyCards = TimerStorage.shared.getAllDailyTimes()
        
        let avgTime = TimerStorage.shared.getAverageTime()
        let hours = Int(avgTime) / 3600
        let minutes = (Int(avgTime) % 3600) / 60
        averageTime = String(format: "%dh %dm", hours, minutes)
    }
    
    private func updateTodayTime() {
        let totalTime = TimerStorage.shared.getTodayTime()
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        todayTime = String(format: "%dh %dm", hours, minutes)
        
        let today = Date()
        let appDetails = AppBlockingTracker.shared.getAppBlockingDetails(for: today)
        let currentAppCount = appDetails.count
        
        if currentAppCount != lastLoggedAppCount {
            lastLoggedAppCount = currentAppCount
            if appDetails.isEmpty {
                print("📱 [ActivityView] Hoje: Nenhum app bloqueado com tempo salvo")
            } else {
                print("📱 [ActivityView] Hoje: \(appDetails.count) apps bloqueados com tempo salvo (total: \(Int(totalTime / 60))m)")
            }
        }
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


