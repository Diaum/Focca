import SwiftUI
import Combine

class TimerManager: ObservableObject {
    @Published var elapsedTime: String = "0h 0m 0s"
    private var timer: Timer?
    private var startDate: Date?
    private let sharedDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard

    func start() {
        // Invalida o timer anterior se existir
        timer?.invalidate()
        timer = nil
        
        let blockedDate = sharedDefaults.object(forKey: "blocked_start_date") as? Date
        if let startDate = blockedDate {
            self.startDate = startDate
        } else {
            let now = Date()
            self.startDate = now
            sharedDefaults.set(now, forKey: "blocked_start_date")
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.updateTime()
            }
            RunLoop.main.add(self.timer!, forMode: .common)
            self.updateTime()
        }
    }
    
    // Para o timer sem remover o estado (usado quando a view desaparece)
    func stop() {
        timer?.invalidate()
        timer = nil
        // NÃO remove o blocked_start_date aqui - isso só deve acontecer quando o bloqueio realmente termina
    }
    
    // Finaliza o timer, computa o tempo e remove o estado (chamado quando o bloqueio realmente termina)
    func finalize() {
        timer?.invalidate()
        timer = nil
        
        guard let startDate = startDate else { return }
        
        TimerStorage.shared.splitOvernightTime(from: startDate, to: Date())
        
        self.startDate = nil
        sharedDefaults.removeObject(forKey: "blocked_start_date")
    }
    
    private func updateTime() {
        var dateToUse = startDate
        if dateToUse == nil {
            if let blockedDate = sharedDefaults.object(forKey: "blocked_start_date") as? Date {
                dateToUse = blockedDate
                self.startDate = blockedDate
            } else {
                let currentTime = elapsedTime
                if currentTime != "0h 0m 0s" {
                    DispatchQueue.main.async { [weak self] in
                        self?.elapsedTime = "0h 0m 0s"
                    }
                }
                return
            }
        }
        
        guard let startDate = dateToUse else {
            return
        }
        
        let elapsed = Date().timeIntervalSince(startDate)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        
        let newTime = String(format: "%dh %dm %ds", hours, minutes, seconds)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, newTime != self.elapsedTime else { return }
            self.elapsedTime = newTime
            
            let hours = Int(elapsed) / 3600
            let minutes = (Int(elapsed) % 3600) / 60
            
            if hours >= 1 {
                AwardManager.shared.checkFocusDurationAward(duration: elapsed, awardId: "1_hour_focus")
            } else if minutes >= 30 {
                AwardManager.shared.checkFocusDurationAward(duration: elapsed, awardId: "30_min_focus")
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

struct TimerComponent: View {
    @StateObject private var timerManager = TimerManager()
    let isActive: Bool
    
    private var timeComponents: (hours: String, minutes: String, seconds: String) {
        let parts = timerManager.elapsedTime.components(separatedBy: " ")
        let hours = parts.first ?? "0h"
        
        var minutes = "00m"
        if parts.count > 1 {
            let minutesValue = parts[1].replacingOccurrences(of: "m", with: "")
            if let value = Int(minutesValue) {
                minutes = String(format: "%02dm", value)
            } else {
                minutes = parts[1]
            }
        }
        
        var seconds = "00s"
        if parts.count > 2 {
            let secondsValue = parts[2].replacingOccurrences(of: "s", with: "")
            if let value = Int(secondsValue) {
                seconds = String(format: "%02ds", value)
            } else {
                seconds = parts[2]
            }
        }
        
        return (hours, minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(timeComponents.hours)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(isActive ? .white : Color(hex: "1C1C1E"))
            Text(timeComponents.minutes)
                .font(.system(size: 42, weight: .light, design: .rounded))
                .foregroundColor(isActive ? .white : Color(hex: "1C1C1E"))
            Text(timeComponents.seconds)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(isActive ? Color.white.opacity(0.7) : Color(hex: "8E8E93"))
        }
        .id("timer-\(isActive)")
        .onAppear {
            if isActive {
                timerManager.start()
            }
        }
        .onDisappear {
            timerManager.stop()
        }
        .onChange(of: isActive) { active in
            if active {
                timerManager.start()
            } else {
                timerManager.finalize()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BlockingStarted"))) { _ in
            if isActive {
                timerManager.start()
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

