import SwiftUI

struct ActivityView: View {
    @Binding var selectedTab: Int
    @State private var showModeSheet = false
    @State private var todayTime: String = "0h 0m"
    @State private var averageTime: String = "0h 0m"
    @State private var dailyCards: [(date: Date, time: TimeInterval)] = []
    // Permite injetar dados no Preview para mostrar cards
    let initialDailyCards: [(date: Date, time: TimeInterval)]?
    
    init(selectedTab: Binding<Int>, initialDailyCards: [(date: Date, time: TimeInterval)]? = nil) {
        self._selectedTab = selectedTab
        self.initialDailyCards = initialDailyCards
    }
        
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
//            .overlay(ReferenceGrid(spacing: 24, color: .red.opacity(0.15)))
            
            VStack(spacing: 0) {
                Spacer(minLength: 30)
                
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("Today")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        
                        Text(todayTime)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                    
                    VStack(spacing: 4) {
                        Text("Average")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        
                        Text(averageTime)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                }
                .padding(.top, 0)
                .padding(.bottom, 60)
                
                if dailyCards.isEmpty {
                    Spacer()
                    
                    Text("Activities will appear after your first day using Brick")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "9E9EA3"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ], spacing: 10) {
                            ForEach(dailyCards, id: \.date) { card in
                                DailyCard(date: card.date, time: card.time)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                

                                
                WhiteRoundedBottomPlain()
                    .padding(.bottom, -6)
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -48)

                
            }
            
        }
        .sheet(isPresented: $showModeSheet) {
            ModeSelectionSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .preferredColorScheme(.light)
        .onAppear {
            if let injected = initialDailyCards {
                // Usa os dados de preview quando fornecidos
                dailyCards = injected
            } else {
                loadActivityData()
            }
            updateTodayTime()
            
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


