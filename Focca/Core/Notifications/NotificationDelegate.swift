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
            markScheduleForActivation(notification: notification)
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
            markScheduleForActivation(notification: notification)
            
            // Tenta ativar o schedule mesmo em background usando Background Task
            if UIApplication.shared.applicationState != .active {
                print("📱 [NotificationDelegate] App está em background, tentando ativar schedule via Background Task...")
                scheduleBackgroundActivation()
            }
            
            ScheduleManager.shared.checkSchedules()
            completionHandler()
            return
        }
        
        // Trata ações de botão (START_NOW)
        let category = notification.request.content.categoryIdentifier
        if category == "SCHEDULE_START_NOW" && response.actionIdentifier == "START_NOW" {
            print("📱 [NotificationDelegate] Ação START_NOW detectada, ativando schedule...")
            markScheduleForActivation(notification: notification)
            ScheduleManager.shared.checkSchedules()
        }
        
        completionHandler()
    }
    
    /// Marca no UserDefaults que um schedule precisa ser ativado
    /// Isso garante que mesmo se o app estiver em background, o schedule será ativado quando o app for aberto
    private func markScheduleForActivation(notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        let identifier = notification.request.identifier
        
        // Extrai o scheduleId do userInfo ou do identifier
        var scheduleId: String?
        if let id = userInfo["scheduleId"] as? String {
            scheduleId = id
        } else if identifier.contains("schedule_") {
            // Extrai o scheduleId do identifier (formato: schedule_{id}_weekday_{weekday}_start)
            let components = identifier.components(separatedBy: "_")
            if components.count >= 2 && components[0] == "schedule" {
                scheduleId = components[1]
            }
        }
        
        if let scheduleId = scheduleId {
            let userDefaults = UserDefaults.standard
            userDefaults.set(true, forKey: "pending_schedule_activation")
            userDefaults.set(scheduleId, forKey: "pending_schedule_id")
            userDefaults.set(Date(), forKey: "pending_schedule_timestamp")
            userDefaults.synchronize()
            print("📱 [NotificationDelegate] Schedule marcado para ativação: \(scheduleId)")
        }
    }
    
    /// Agenda uma Background Task para tentar ativar o schedule
    /// Nota: Background Tasks têm limitações no iOS e podem não ser executadas imediatamente
    private func scheduleBackgroundActivation() {
        // Marca que precisa verificar schedules quando o app for aberto
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "should_check_schedules_on_launch")
        userDefaults.synchronize()
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

