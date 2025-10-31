import Foundation
import UserNotifications

/// Componente responsável pela configuração de categorias de notificações
/// Preparado para futuras ações customizadas (se necessário)
struct NotificationCategories {
    static func setup() {
        // Por enquanto, não há ações customizadas
        // Mas mantém a estrutura para futuras extensões
        // Exemplo futuro:
        // let action = UNNotificationAction(identifier: "VIEW_SCHEDULE", title: "View Schedule")
        // let category = UNNotificationCategory(identifier: "SCHEDULE_REMINDER", actions: [action], intentIdentifiers: [])
        // UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

