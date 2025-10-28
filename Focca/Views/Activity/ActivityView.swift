import SwiftUI

struct ActivityView: View {
    @Binding var selectedTab: Int
    @State private var showModeSheet = false
    @State private var todayTime: String = "0h 0m"
    @State private var averageTime: String = "0h 0m"
    @State private var dailyCards: [(date: Date, time: TimeInterval)] = []
        
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("Today")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        
                        Text(todayTime)
                            .font(.system(size: 38, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                    
                    VStack(spacing: 4) {
                        Text("Average")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        
                        Text(averageTime)
                            .font(.system(size: 38, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 40)
                
                if dailyCards.isEmpty {
                    Spacer()
                    
                    Text("Activities will appear after your first day using Brick")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "9E9EA3"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                                    
                    WhiteRoundedBottom(action: {})
                        .padding(.bottom, 0)
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
                        .padding(.bottom, 100)
                    }
                }
                
                TabBar(selectedTab: $selectedTab)
                    .padding(.top, 10)

            }
        }
        .sheet(isPresented: $showModeSheet) {
            ModeSelectionSheet()
        }
        .onAppear {
            loadActivityData()
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
    ActivityView(selectedTab: .constant(2))
}


