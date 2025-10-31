import Foundation
import Combine
import ManagedSettings
import FamilyControls

// Gerenciador de schedules: verifica horários e ativa/desativa bloqueios automaticamente
class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()
    
    @Published var currentSchedule: ScheduleModel?
    @Published var isBlockedBySchedule: Bool = false
    
    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    
    private init() {
        print("📅 [ScheduleManager] Inicializando ScheduleManager...")
        startMonitoring()
    }
    
    // Inicia o monitoramento de schedules (verifica a cada minuto)
    func startMonitoring() {
        print("📅 [ScheduleManager] Iniciando monitoramento (verifica a cada 60s)")
        timer?.invalidate()
        // Usa RunLoop.main para garantir que o timer rode na thread principal
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkSchedules()
        }
        RunLoop.main.add(timer!, forMode: .common)
        // Verifica imediatamente ao iniciar
        print("📅 [ScheduleManager] Executando verificação inicial...")
        checkSchedules()
    }
    
    // Para o monitoramento
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // Carrega todos os schedules salvos (incluindo inativos)
    private func loadAllSchedules() -> [ScheduleModel] {
        guard let data = userDefaults.data(forKey: "all_schedules"),
              let decoded = try? JSONDecoder().decode([ScheduleModel].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // Carrega apenas schedules ativos
    func loadSchedules() -> [ScheduleModel] {
        return loadAllSchedules().filter { $0.isActive }
    }
    
    // Salva um schedule (mantém todos os schedules, inclusive inativos)
    func saveSchedule(_ schedule: ScheduleModel) {
        print("📅 [ScheduleManager] Salvando schedule para modo '\(schedule.modeName)'")
        print("   - ID: \(schedule.id)")
        print("   - Dias: \(schedule.weekdays.sorted())")
        
        let calendar = Calendar.current
        let startComps = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
        let endComps = calendar.dateComponents([.hour, .minute], from: schedule.endTime)
        print("   - Horário: \(String(format: "%02d:%02d", startComps.hour ?? 0, startComps.minute ?? 0)) - \(String(format: "%02d:%02d", endComps.hour ?? 0, endComps.minute ?? 0))")
        print("   - Válido: \(schedule.isValid())")
        print("   - Ativo: \(schedule.isActive)")
        
        var schedules = loadAllSchedules()
        // Remove schedule antigo com mesmo id se existir
        schedules.removeAll { $0.id == schedule.id }
        schedules.append(schedule)
        saveAllSchedules(schedules)
        
        print("📅 [ScheduleManager] Schedule salvo! Total de schedules: \(schedules.count)")
        checkSchedules()
    }
    
    // Remove um schedule
    func removeSchedule(id: String) {
        var schedules = loadAllSchedules()
        schedules.removeAll { $0.id == id }
        saveAllSchedules(schedules)
        checkSchedules()
    }
    
    // Salva todos os schedules
    private func saveAllSchedules(_ schedules: [ScheduleModel]) {
        if let encoded = try? JSONEncoder().encode(schedules) {
            userDefaults.set(encoded, forKey: "all_schedules")
        }
    }
    
    // Verifica todos os schedules e ativa/desativa conforme necessário
    func checkSchedules() {
        let schedules = loadSchedules()
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        print("\n🔍 [ScheduleManager] Verificando schedules às \(timeFormatter.string(from: now))")
        print("   - Dia da semana: \(weekday) (1=Dom, 2=Seg, ..., 7=Sáb)")
        print("   - Schedules ativos encontrados: \(schedules.count)")
        
        for schedule in schedules {
            let startComps = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
            let endComps = calendar.dateComponents([.hour, .minute], from: schedule.endTime)
            let startStr = String(format: "%02d:%02d", startComps.hour ?? 0, startComps.minute ?? 0)
            let endStr = String(format: "%02d:%02d", endComps.hour ?? 0, endComps.minute ?? 0)
            
            print("   📋 Schedule '\(schedule.modeName)':")
            print("      - Dias: \(schedule.weekdays.sorted())")
            print("      - Horário: \(startStr) - \(endStr)")
            print("      - Contém hoje? \(schedule.weekdays.contains(weekday))")
            print("      - Deve estar ativo? \(schedule.shouldBeActiveNow())")
        }
        
        // Encontra o schedule que deve estar ativo agora
        let activeSchedule = schedules.first { schedule in
            let containsDay = schedule.weekdays.contains(weekday)
            let shouldBeActive = schedule.shouldBeActiveNow()
            print("   🔎 Testando '\(schedule.modeName)': dia=\(containsDay), ativo=\(shouldBeActive)")
            return containsDay && shouldBeActive
        }
        
        // Executa na thread principal mas sem forçar atualização de UI desnecessária
        if Thread.isMainThread {
            processScheduleCheck(activeSchedule: activeSchedule)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.processScheduleCheck(activeSchedule: activeSchedule)
            }
        }
    }
    
    private func processScheduleCheck(activeSchedule: ScheduleModel?) {
        guard let self = self else { return }
        
        if let schedule = activeSchedule {
            print("   ✅ Schedule '\(schedule.modeName)' deve estar ATIVO agora")
            // Deve estar bloqueado
            if !self.isBlockedBySchedule {
                print("   🚀 Ativando schedule...")
                self.activateSchedule(schedule)
            } else if self.currentSchedule?.id != schedule.id {
                // Mudou de schedule, atualiza
                print("   🔄 Mudando de schedule...")
                self.deactivateCurrentSchedule()
                self.activateSchedule(schedule)
            } else {
                print("   ℹ️ Schedule já está ativo")
            }
        } else {
            print("   ❌ Nenhum schedule deve estar ativo agora")
            // Não deve estar bloqueado
            if self.isBlockedBySchedule {
                print("   🛑 Desativando schedule atual...")
                self.deactivateCurrentSchedule()
            }
        }
    }
    
    // Ativa um schedule (bloqueia os apps)
    private func activateSchedule(_ schedule: ScheduleModel) {
        print("🚀 [ScheduleManager] Ativando schedule '\(schedule.modeName)'")
        
        guard let data = userDefaults.data(forKey: "mode_\(schedule.modeName)_selection"),
              let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            print("   ❌ Erro: Modo '\(schedule.modeName)' não encontrado ou sem seleção de apps")
            return
        }
        
        print("   ✅ Modo '\(schedule.modeName)' encontrado com \(saved.applicationTokens.count) apps")
        
        let store = ManagedSettingsStore()
        let apps = Set(saved.applicationTokens.compactMap { Application(token: $0) })
        store.application.blockedApplications = apps
        
        print("   ✅ Apps bloqueados: \(apps.count)")
        
        // Marca início do bloqueio por schedule
        let now = Date()
        userDefaults.set(now, forKey: "blocked_start_date")
        userDefaults.set(true, forKey: "blocked_by_schedule")
        userDefaults.set(schedule.modeName, forKey: "active_mode_name")
        userDefaults.set(saved.applicationTokens.count, forKey: "active_mode_app_count")
        
        currentSchedule = schedule
        isBlockedBySchedule = true
        
        print("   ✅ Schedule ativado com sucesso!")
        
        // Notifica o app para mudar para BlockedView
        NotificationCenter.default.post(name: NSNotification.Name("ScheduleActivated"), object: nil)
    }
    
    // Desativa o schedule atual (desbloqueia e computa tempo)
    private func deactivateCurrentSchedule() {
        guard let schedule = currentSchedule else {
            print("   ⚠️ Tentando desativar mas não há schedule ativo")
            return
        }
        
        print("🛑 [ScheduleManager] Desativando schedule '\(schedule.modeName)'")
        
        let store = ManagedSettingsStore()
        store.application.blockedApplications = nil
        
        print("   ✅ Apps desbloqueados")
        
        // Computa o tempo no TimerStorage
        if let startDate = userDefaults.object(forKey: "blocked_start_date") as? Date {
            let duration = Date().timeIntervalSince(startDate)
            print("   ⏱️ Tempo bloqueado: \(Int(duration / 60)) minutos")
            TimerStorage.shared.splitOvernightTime(from: startDate, to: Date())
            print("   ✅ Tempo computado no TimerStorage")
        }
        
        userDefaults.removeObject(forKey: "blocked_start_date")
        userDefaults.removeObject(forKey: "blocked_by_schedule")
        
        currentSchedule = nil
        isBlockedBySchedule = false
        
        print("   ✅ Schedule desativado com sucesso!")
        
        // Notifica o app para mudar para UnlockedView
        NotificationCenter.default.post(name: NSNotification.Name("ScheduleDeactivated"), object: nil)
    }
}

