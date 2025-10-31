import Foundation
import UserNotifications

/// Gerenciador principal de notificações
/// Orquestra os componentes para agendar, cancelar e gerenciar notificações
class NotificationManager {
    static let shared = NotificationManager()
    
    private let scheduler = NotificationScheduler()
    private let permissions = NotificationPermissions()
    
    private init() {
        NotificationCategories.setup()
    }
    
    // MARK: - Permissões
    
    /// Solicita permissão para enviar notificações
    func requestAuthorization() async -> Bool {
        return await permissions.requestAuthorization()
    }
    
    /// Verifica o status de autorização atual
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        return await permissions.checkAuthorizationStatus()
    }
    
    // MARK: - Agendamento de Notificações
    
    /// Agenda uma notificação 10 minutos antes de um schedule começar
    /// - Parameter schedule: O schedule que vai começar
    func scheduleNotification(for schedule: ScheduleModel) {
        print("🔔 [NotificationManager] Tentando agendar notificações para schedule '\(schedule.modeName)'")
        print("   Schedule ID: \(schedule.id)")
        print("   Weekdays: \(schedule.weekdays.sorted())")
        print("   Is Active: \(schedule.isActive)")
        
        // Remove notificações antigas para este schedule
        cancelNotification(for: schedule.id)
        
        // Validações
        guard schedule.isActive else {
            print("⚠️ [NotificationManager] Schedule inativo, não será agendada notificação")
            return
        }
        
        // Verifica se o modo do schedule ainda existe (não foi deletado)
        let modeExistsKey = "mode_\(schedule.modeName)_exists"
        guard UserDefaults.standard.bool(forKey: modeExistsKey) else {
            print("⚠️ [NotificationManager] Modo '\(schedule.modeName)' foi deletado, não será agendada notificação")
            return
        }
        
        // Verifica permissões antes de agendar
        Task {
            let status = await checkAuthorizationStatus()
            await MainActor.run {
                guard status == .authorized else {
                    print("⚠️ [NotificationManager] Notificações não autorizadas! Status: \(status.rawValue)")
                    print("   Use NotificationManager.shared.requestAuthorization() para solicitar permissão")
                    return
                }
                
                print("✅ [NotificationManager] Permissões OK, agendando notificações...")
                
                // Agenda notificações para cada dia da semana do schedule (semanal)
                for weekday in schedule.weekdays {
                    scheduler.scheduleNotificationForWeekday(schedule: schedule, weekday: weekday)
                }
                
                // Aguarda um pouco para garantir que as notificações semanais foram processadas
                // ANTES de verificar se precisa agendar para hoje (evita duplicatas)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Se o schedule começar HOJE, agenda notificação também para hoje
                    // (mas só se não houver notificação semanal que já cobre)
                    self.scheduler.scheduleNotificationForTodayIfNeeded(schedule: schedule)
                }
                
                print("✅ [NotificationManager] Notificações agendadas para schedule '\(schedule.modeName)'")
                
                // Lista notificações pendentes para debug (após 1 segundo)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.listPendingNotifications()
                }
            }
        }
    }
    
    // MARK: - Cancelamento de Notificações
    
    /// Cancela todas as notificações de um schedule específico
    func cancelNotification(for scheduleId: String) {
        scheduler.cancelNotifications(for: scheduleId)
    }
    
    /// Cancela todas as notificações de um modo específico (quando o modo é deletado)
    func cancelNotificationsForMode(modeName: String) {
        // Busca todos os schedules do modo para cancelar suas notificações
        let allSchedules = ScheduleManager.shared.loadAllSchedules()
        let schedulesForMode = allSchedules.filter { $0.modeName == modeName }
        
        for schedule in schedulesForMode {
            cancelNotification(for: schedule.id)
        }
        
        print("🗑️ [NotificationManager] Todas as notificações do modo '\(modeName)' foram canceladas")
    }
    
    /// Cancela todas as notificações pendentes (para debug/limpeza)
    func cancelAllNotifications() {
        scheduler.cancelAllNotifications()
    }
    
    // MARK: - Atualização de Notificações
    
    /// Atualiza as notificações quando um schedule é modificado
    func updateNotifications(for schedule: ScheduleModel) {
        cancelNotification(for: schedule.id)
        scheduleNotification(for: schedule)
    }
    
    // MARK: - Debug/Test
    
    /// Dispara uma notificação de teste imediatamente (para debug)
    func sendTestNotification() {
        // Verifica permissões primeiro
        Task {
            let status = await checkAuthorizationStatus()
            await MainActor.run {
                guard status == .authorized else {
                    print("❌ [NotificationManager] Test: Notificações não autorizadas. Status: \(status.rawValue)")
                    return
                }
                
                print("🧪 [NotificationManager] Enviando notificação de teste...")
                
                // Cria conteúdo de teste
                let content = UNMutableNotificationContent()
                content.title = "Schedule Starting Soon"
                content.body = "Your 'Test Mode' schedule starts in 10 minutes"
                content.sound = .default
                content.badge = 1
                
                // Trigger imediato (5 segundos para teste)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                
                // Identificador único para teste
                let identifier = "test_notification_\(Date().timeIntervalSince1970)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ [NotificationManager] Test: Erro ao agendar: \(error.localizedDescription)")
                    } else {
                        print("✅ [NotificationManager] Test: Notificação de teste agendada para 5 segundos")
                        
                        // Verifica se foi realmente agendada
                        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                            let found = requests.contains { $0.identifier == identifier }
                            print("   Verificação: Notificação \(found ? "encontrada" : "NÃO encontrada") nas pendentes")
                        }
                    }
                }
            }
        }
    }
    
    /// Dispara uma notificação de teste IMEDIATA (sem delay) para debug
    func sendImmediateTestNotification() {
        Task {
            let status = await checkAuthorizationStatus()
            await MainActor.run {
                guard status == .authorized else {
                    print("❌ [NotificationManager] Test: Notificações não autorizadas. Status: \(status.rawValue)")
                    return
                }
                
                print("🧪 [NotificationManager] Enviando notificação IMEDIATA de teste...")
                
                // Cria conteúdo de teste
                let content = UNMutableNotificationContent()
                content.title = "Schedule Starting Soon"
                content.body = "Your 'Test Mode' schedule starts in 10 minutes (IMMEDIATE TEST)"
                content.sound = .default
                content.badge = 1
                
                // Usa nil para trigger = notificação imediata (mas requer push notification ou local notification delivery date)
                // Alternativa: usar um trigger muito curto (1 segundo)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                // Identificador único para teste
                let identifier = "test_immediate_\(Date().timeIntervalSince1970)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ [NotificationManager] Test Immediate: Erro ao agendar: \(error.localizedDescription)")
                    } else {
                        print("✅ [NotificationManager] Test Immediate: Notificação agendada para 1 segundo")
                    }
                }
            }
        }
    }
    
    /// Lista todas as notificações pendentes (para debug)
    func listPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let scheduleNotifications = requests.filter { $0.identifier.hasPrefix("schedule_") }
            
            print("📋 [NotificationManager] Debug: Total de notificações pendentes: \(requests.count)")
            print("📋 [NotificationManager] Debug: Notificações de schedules: \(scheduleNotifications.count)")
            
            for notification in scheduleNotifications {
                if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                    let comps = trigger.dateComponents
                    let weekday = comps.weekday ?? 0
                    let hour = comps.hour ?? 0
                    let minute = comps.minute ?? 0
                    let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    let weekdayName = weekday > 0 ? weekdayNames[(weekday - 1) % 7] : "?"
                    
                    print("   📌 ID: \(notification.identifier)")
                    print("      Title: \(notification.content.title)")
                    print("      Body: \(notification.content.body)")
                    print("      Trigger: \(weekdayName) \(String(format: "%02d:%02d", hour, minute))")
                    print("      Repeats: \(trigger.repeats)")
                    print("")
                }
            }
        }
    }

    /// Envia uma notificação simples informativa imediata (1s)
    func sendInfoNotification(title: String, body: String) {
        Task {
            let status = await checkAuthorizationStatus()
            await MainActor.run {
                guard status == .authorized else {
                    print("⚠️ [NotificationManager] Sem permissão para enviar notificação informativa")
                    return
                }
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let identifier = "info_\(Date().timeIntervalSince1970)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ [NotificationManager] Erro ao enviar notificação informativa: \(error.localizedDescription)")
                    } else {
                        print("✅ [NotificationManager] Notificação informativa enviada")
                    }
                }
            }
        }
    }
}

