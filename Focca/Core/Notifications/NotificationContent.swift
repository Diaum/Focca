import Foundation
import UserNotifications

/// Componente responsável por criar o conteúdo das notificações
struct NotificationContent {
    /// Cria o conteúdo de uma notificação de schedule
    /// - Parameter schedule: O schedule que vai começar
    /// - Returns: Conteúdo configurado seguindo as melhores práticas da Apple
    static func createScheduleNotification(for schedule: ScheduleModel) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Título claro e conciso (melhor prática Apple)
        content.title = "Schedule Starting Soon"
        
        // Mensagem personalizada com o nome do modo
        content.body = "Your '\(schedule.modeName)' schedule starts in 10 minutes"
        
        // Som padrão do sistema
        content.sound = .default
        
        // Badge atualizado
        content.badge = 1
        
        // Categoria para possíveis ações (abrir app / iniciar agora)
        content.categoryIdentifier = "SCHEDULE_REMINDER"
        
        return content
    }

    /// Conteúdo para notificação no horário exato do início
    static func createScheduleStartNowNotification(for schedule: ScheduleModel) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Agora é hora de FOCCAR!"
        content.body = "O Focca ja vai ativar, o modo '\(schedule.modeName)' está começando agora"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "SCHEDULE_START_NOW"
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        return content
    }
}

