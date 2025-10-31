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
        // Remove notificações antigas para este schedule
        cancelNotification(for: schedule.id)
        
        // Validações
        guard schedule.isActive else {
            return
        }
        
        // Verifica se o modo do schedule ainda existe (não foi deletado)
        let modeExistsKey = "mode_\(schedule.modeName)_exists"
        guard UserDefaults.standard.bool(forKey: modeExistsKey) else {
            return
        }
        
        // Verifica permissões antes de agendar
        Task {
            let status = await checkAuthorizationStatus()
            await MainActor.run {
                guard status == .authorized else {
                    return
                }
                
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
    
    /// Envia uma notificação simples informativa imediata (1s)
    func sendInfoNotification(title: String, body: String) {
        Task {
            let status = await checkAuthorizationStatus()
            await MainActor.run {
                guard status == .authorized else {
                    return
                }
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let identifier = "info_\(Date().timeIntervalSince1970)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { _ in }
            }
        }
    }
}

