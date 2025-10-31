import Foundation
import UserNotifications
import UIKit

/// Delegate para gerenciar notificações quando o app está em primeiro plano
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    /// Mostra notificações mesmo quando o app está em primeiro plano
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Mostra banner, som e badge mesmo em primeiro plano
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    /// Trata quando o usuário toca na notificação
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let category = response.notification.request.content.categoryIdentifier
        if category == "SCHEDULE_START_NOW" && response.actionIdentifier == "START_NOW" {
            // Inicia o schedule imediatamente (sem abrir app)
            ScheduleManager.shared.checkSchedules()
        }
        completionHandler()
    }
}

