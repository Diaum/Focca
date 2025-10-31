import Foundation
import UserNotifications

/// Componente responsável pela configuração de categorias de notificações
/// Define ações para lembretes e início imediato do schedule
struct NotificationCategories {
    static func setup() {
        let center = UNUserNotificationCenter.current()

        // Ações para lembrete (10 min antes)
        let openAction = UNNotificationAction(identifier: "OPEN_APP", title: "Abrir", options: [.foreground])
        let reminderCategory = UNNotificationCategory(
            identifier: "SCHEDULE_REMINDER",
            actions: [openAction],
            intentIdentifiers: [],
            options: []
        )

        // Ação para iniciar agora (no horário exato)
        let startNowAction = UNNotificationAction(identifier: "START_NOW", title: "Iniciar agora", options: [])
        let startNowCategory = UNNotificationCategory(
            identifier: "SCHEDULE_START_NOW",
            actions: [startNowAction, openAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([reminderCategory, startNowCategory])
    }
}

