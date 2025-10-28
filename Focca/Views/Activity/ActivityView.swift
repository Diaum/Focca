import SwiftUI

struct ActivityView: View {
    @Binding var selectedTab: Int
    @State private var showModeSheet = false
    @State private var todayTime: String = "0h 0m"
        
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
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                    
                    VStack(spacing: 4) {
                        Text("Average")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        
                        Text("0:00")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 60)
                
                Spacer()

                Text("Activities will appear after your first day using Brick")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "9E9EA3"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                                
                WhiteRoundedBottom(action: {})
                    .padding(.bottom, 0)
                
                TabBar(selectedTab: $selectedTab)
                    .padding(.top, 10)

            }
        }
        .sheet(isPresented: $showModeSheet) {
            ModeSelectionSheet()
        }
        .onAppear {
            updateTodayTime()
            
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                DispatchQueue.main.async {
                    self.updateTodayTime()
                }
            }
        }
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


