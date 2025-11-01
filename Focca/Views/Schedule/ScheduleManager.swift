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
    private func loadAllSchedulesInternal() -> [ScheduleModel] {
        guard let data = userDefaults.data(forKey: "all_schedules"),
              let decoded = try? JSONDecoder().decode([ScheduleModel].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // Carrega apenas schedules ativos de modos que ainda existem
    func loadSchedules() -> [ScheduleModel] {
        return loadAllSchedulesInternal().filter { schedule in
            // Filtra apenas schedules ativos
            guard schedule.isActive else { return false }
            
            // Verifica se o modo do schedule ainda existe (não foi deletado)
            let modeExistsKey = "mode_\(schedule.modeName)_exists"
            let modeExists = UserDefaults.standard.bool(forKey: modeExistsKey)
            
            if !modeExists {
                print("   🧹 [ScheduleManager] Removendo schedule órfão do modo deletado: '\(schedule.modeName)'")
                // Remove automaticamente schedules órfãos (de modos deletados)
                DispatchQueue.main.async {
                    self.removeSchedule(id: schedule.id)
                }
                return false
            }
            
            return true
        }
    }
    
    // Método público para carregar todos os schedules (para validação de conflitos)
    func loadAllSchedules() -> [ScheduleModel] {
        return loadAllSchedulesInternal()
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
        
        var schedules = loadAllSchedulesInternal()
        let isUpdate = schedules.contains(where: { $0.id == schedule.id })
        
        // Remove schedule antigo com mesmo id se existir (e suas notificações)
        if isUpdate {
            NotificationManager.shared.cancelNotification(for: schedule.id)
        }
        schedules.removeAll { $0.id == schedule.id }
        schedules.append(schedule)
        saveAllSchedules(schedules)
        
        print("📅 [ScheduleManager] Schedule \(isUpdate ? "atualizado" : "salvo")! Total de schedules: \(schedules.count)")
        
        // Agenda/atualiza notificação 10 minutos antes do schedule começar
        if schedule.isActive {
            NotificationManager.shared.scheduleNotification(for: schedule)
        }
        
        checkSchedules()
    }
    
    // Remove um schedule por ID
    func removeSchedule(id: String) {
        // Cancela notificações do schedule antes de remover
        NotificationManager.shared.cancelNotification(for: id)
        
        var schedules = loadAllSchedulesInternal()
        schedules.removeAll { $0.id == id }
        saveAllSchedules(schedules)
        checkSchedules()
    }
    
    // Remove todos os schedules de um modo específico (quando o modo é deletado)
    func removeSchedulesForMode(modeName: String) {
        // Cancela todas as notificações do modo antes de remover
        NotificationManager.shared.cancelNotificationsForMode(modeName: modeName)
        
        var schedules = loadAllSchedulesInternal()
        let schedulesToRemove = schedules.filter { $0.modeName == modeName }
        
        if !schedulesToRemove.isEmpty {
            print("🗑️ [ScheduleManager] Removendo \(schedulesToRemove.count) schedule(s) do modo '\(modeName)'")
            
            // Se algum dos schedules removidos está ativo, desativa primeiro
            for schedule in schedulesToRemove {
                if schedule.id == currentSchedule?.id {
                    print("   ⚠️ Schedule ativo será desativado: '\(schedule.modeName)'")
                    manualUnblock()
                }
            }
            
            // Remove os schedules
            schedules.removeAll { $0.modeName == modeName }
            saveAllSchedules(schedules)
            
            print("✅ [ScheduleManager] Schedules removidos. Total restante: \(schedules.count)")
            checkSchedules()
        }
    }
    
    // Feature 5: Desativa o schedule do dia atual se usuário desbloquear antes do fim
    func disableScheduleForToday(scheduleId: String) {
        guard let schedule = loadAllSchedulesInternal().first(where: { $0.id == scheduleId }) else { return }
        
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        // Verifica se o schedule inclui hoje
        guard schedule.weekdays.contains(weekday) else { return }
        
        // Marca que o schedule foi desativado para hoje
        let key = "schedule_\(scheduleId)_disabled_\(calendar.startOfDay(for: today).timeIntervalSince1970)"
        userDefaults.set(true, forKey: key)
        userDefaults.synchronize()
        
        print("🚫 [ScheduleManager] Schedule '\(schedule.modeName)' desativado para hoje (dia \(weekday))")
        
        // Se este é o schedule atual, desativa manualmente
        if currentSchedule?.id == scheduleId {
            manualUnblock()
        }
    }
    
    // Desbloqueia manualmente quando o usuário clica em "Unbrick"
    func manualUnblock() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Se havia um schedule atual, marca como desativado para hoje para evitar reativação
            if let scheduleId = self.currentSchedule?.id {
                self.markScheduleDisabledForToday(scheduleId: scheduleId)
            }
            self.currentSchedule = nil
            self.isBlockedBySchedule = false
            UserDefaults.standard.removeObject(forKey: "blocked_by_schedule")
            UserDefaults.standard.removeObject(forKey: "blocked_start_date")
            
            // Notifica o app para mudar para UnlockedView
            NotificationCenter.default.post(name: NSNotification.Name("ScheduleDeactivated"), object: nil)
            
            print("🔓 [ScheduleManager] Desbloqueio manual executado")
        }
    }
    
    // Verifica se o schedule está desativado para hoje
    func isScheduleDisabledForToday(scheduleId: String) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let key = "schedule_\(scheduleId)_disabled_\(today.timeIntervalSince1970)"
        return userDefaults.bool(forKey: key)
    }

    // Marca um schedule como desativado para o dia atual (sem efeitos colaterais)
    private func markScheduleDisabledForToday(scheduleId: String) {
        let calendar = Calendar.current
        let todayKey = "schedule_\(scheduleId)_disabled_\(calendar.startOfDay(for: Date()).timeIntervalSince1970)"
        userDefaults.set(true, forKey: todayKey)
        userDefaults.synchronize()
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
            // Feature 5: Verifica se o schedule está desativado para hoje
            if isScheduleDisabledForToday(scheduleId: schedule.id) {
                print("   🔎 Testando '\(schedule.modeName)': DESATIVADO para hoje")
                return false
            }
            
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
        if let schedule = activeSchedule {
            print("   ✅ Schedule '\(schedule.modeName)' deve estar ATIVO agora")
            // Deve estar bloqueado
            if !self.isBlockedBySchedule {
                // Se o usuário já está bloqueado manualmente, não ativa o schedule; desativa para hoje e avisa
                let userIsBlocked = UserDefaults.standard.object(forKey: "blocked_start_date") != nil
                let blockedByScheduleFlag = UserDefaults.standard.bool(forKey: "blocked_by_schedule")
                if userIsBlocked && !blockedByScheduleFlag {
                    print("   ⚠️ Usuário já está focado (bloqueio manual). Não ativando schedule '")
                    self.markScheduleDisabledForToday(scheduleId: schedule.id)
                    NotificationManager.shared.sendInfoNotification(
                        title: "Schedule ignorado",
                        body: "Você já está focado. O schedule '\(schedule.modeName)' foi desativado hoje."
                    )
                    return
                }
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
        
        print("   ✅ Modo '\(schedule.modeName)' encontrado com \(CategoryExpander.totalItemCount(saved)) items")

        // Block both apps and categories
        CategoryExpander.blockSelection(saved)

        print("   ✅ Apps e categorias bloqueados")

        // Marca início do bloqueio por schedule
        let now = Date()
        userDefaults.set(now, forKey: "blocked_start_date")
        userDefaults.set(true, forKey: "blocked_by_schedule")
        userDefaults.set(schedule.modeName, forKey: "active_mode_name")
        userDefaults.set(CategoryExpander.totalItemCount(saved), forKey: "active_mode_app_count")
        
        currentSchedule = schedule
        isBlockedBySchedule = true
        
        print("   ✅ Schedule ativado com sucesso!")
        
        // Notifica o app para mudar para BlockedView
        NotificationCenter.default.post(name: NSNotification.Name("ScheduleActivated"), object: nil)

        // Inicia Live Activity
        LiveActivityManager.startIfSupported(startDate: now)
    }
    
    // Desativa o schedule atual (desbloqueia e computa tempo)
    private func deactivateCurrentSchedule() {
        guard let schedule = currentSchedule else {
            print("   ⚠️ Tentando desativar mas não há schedule ativo")
            return
        }
        
        print("🛑 [ScheduleManager] Desativando schedule '\(schedule.modeName)'")

        // Unblock all apps and categories
        CategoryExpander.unblockAll()

        print("   ✅ Apps e categorias desbloqueados")
        
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

        // Encerra Live Activity
        LiveActivityManager.endAll()
    }
}

