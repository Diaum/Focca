import SwiftUI
import Combine

class TimerManager: ObservableObject {
    @Published var elapsedTime: String = "0h 0m 0s"
    private var timer: Timer?
    private var startDate: Date?
    
    func start() {
        let blockedDate = UserDefaults.standard.object(forKey: "blocked_start_date") as? Date
        if let startDate = blockedDate {
            self.startDate = startDate
        } else {
            let now = Date()
            self.startDate = now
            UserDefaults.standard.set(now, forKey: "blocked_start_date")
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
        updateTime()
    }
    
    func stop() {
        guard let startDate = startDate else { return }
        
        timer?.invalidate()
        timer = nil
        
        TimerStorage.shared.splitOvernightTime(from: startDate, to: Date())
        
        self.startDate = nil
        UserDefaults.standard.removeObject(forKey: "blocked_start_date")
    }
    
    private func updateTime() {
        guard let startDate = startDate else {
            elapsedTime = "0h 0m 0s"
            return
        }
        
        let elapsed = Date().timeIntervalSince(startDate)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        
        elapsedTime = String(format: "%dh %dm %ds", hours, minutes, seconds)
    }
}

struct TimerComponent: View {
    @StateObject private var timerManager = TimerManager()
    let isActive: Bool
    
    var body: some View {
        Text(timerManager.elapsedTime)
            .font(.system(size: 42, weight: .semibold, design: .rounded))
            .foregroundColor(isActive ? .white : Color(hex: "1C1C1E"))
            .onAppear {
                if isActive {
                    timerManager.start()
                }
            }
            .onChange(of: isActive) { active in
                if active {
                    timerManager.start()
                } else {
                    timerManager.stop()
                }
            }
    }
}

#Preview {
    VStack {
        TimerComponent(isActive: true)
    }
    .padding()
    .background(Color.black)
}

