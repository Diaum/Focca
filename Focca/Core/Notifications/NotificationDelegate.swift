import Foundation
import UserNotifications
import UIKit

/// Delegate para gerenciar notificações quando o app está em primeiro plano
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    /// Mostra notificações mesmo quando o app está em primeiro plano
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Verifica se é uma notificação de início de schedule e ativa automaticamente
        if shouldActivateSchedule(notification: notification) {
            print("📱 [NotificationDelegate] Notificação de início detectada em primeiro plano, ativando schedule...")
            ScheduleManager.shared.checkSchedules()
        }
        
        // Mostra banner, som e badge mesmo em primeiro plano
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    /// Trata quando o usuário toca na notificação
    /// IMPORTANTE: Este método é chamado quando a notificação é entregue, mesmo em background
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let notification = response.notification
        
        // Verifica se é uma notificação de início de schedule e ativa automaticamente
        if shouldActivateSchedule(notification: notification) {
            print("📱 [NotificationDelegate] Notificação de início detectada (background/foreground), ativando schedule...")
            ScheduleManager.shared.checkSchedules()
            completionHandler()
            return
        }
        
        // Trata ações de botão (START_NOW)
        let category = notification.request.content.categoryIdentifier
        if category == "SCHEDULE_START_NOW" && response.actionIdentifier == "START_NOW" {
            print("📱 [NotificationDelegate] Ação START_NOW detectada, ativando schedule...")
            ScheduleManager.shared.checkSchedules()
        }
        
        completionHandler()
    }
    
    /// Verifica se a notificação deve ativar um schedule automaticamente
    private func shouldActivateSchedule(notification: UNNotification) -> Bool {
        let userInfo = notification.request.content.userInfo
        let category = notification.request.content.categoryIdentifier
        
        // Verifica pelo userInfo (método principal)
        if let action = userInfo["action"] as? String, action == "ACTIVATE_SCHEDULE" {
            return true
        }
        
        // Verifica pela categoria e identificador (fallback)
        if category == "SCHEDULE_START_NOW" {
            let identifier = notification.request.identifier
            // Identificadores de início contêm "_start" no nome
            if identifier.contains("_start") {
                return true
            }
        }
        
        return false
    }
}

