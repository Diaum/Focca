import SwiftUI
import Combine

class TimerManager: ObservableObject {
    @Published var elapsedTime: String = "0h 0m 0s"
    private var timer: Timer?
    private var startDate: Date?
    
    func start() {
        // Para o timer anterior se existir
        stop()
        
        let blockedDate = UserDefaults.standard.object(forKey: "blocked_start_date") as? Date
        if let startDate = blockedDate {
            self.startDate = startDate
        } else {
            let now = Date()
            self.startDate = now
            UserDefaults.standard.set(now, forKey: "blocked_start_date")
        }
        
        // Garante que o timer roda na thread principal e no RunLoop comum
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
        UserDefaults.standard.removeObject(forKey: "blocked_start_date")
    }
    
    private func updateTime() {
        // Se não há startDate local, tenta recuperar do UserDefaults (caso o timer tenha sido recriado)
        var dateToUse = startDate
        if dateToUse == nil {
            if let blockedDate = UserDefaults.standard.object(forKey: "blocked_start_date") as? Date {
                dateToUse = blockedDate
                self.startDate = blockedDate // Restaura o startDate local
            } else {
                // Se não há bloqueio ativo, zera o timer
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
        
        // Atualiza apenas na thread principal e apenas se mudou
        DispatchQueue.main.async { [weak self] in
            guard let self = self, newTime != self.elapsedTime else { return }
            self.elapsedTime = newTime
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

struct TimerComponent: View {
    @StateObject private var timerManager = TimerManager()
    let isActive: Bool
    
    var body: some View {
        Text(timerManager.elapsedTime)
            .font(.system(size: 42, weight: .semibold, design: .rounded))
            .foregroundColor(isActive ? .white : Color(hex: "1C1C1E"))
            .id("timer-\(isActive)") // Evita recriação desnecessária
            .onAppear {
                if isActive {
                    timerManager.start()
                }
            }
            .onDisappear {
                // Apenas pausa o timer, não remove o estado (o bloqueio ainda está ativo)
                timerManager.stop()
            }
            .onChange(of: isActive) { active in
                if active {
                    timerManager.start()
                } else {
                    // Quando o bloqueio realmente termina, finaliza o timer
                    timerManager.finalize()
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

