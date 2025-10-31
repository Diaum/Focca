import Foundation
import UserNotifications
import UIKit

/// Delegate para gerenciar notificações quando o app está em primeiro plano
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    /// Mostra notificações mesmo quando o app está em primeiro plano
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("📬 [NotificationDelegate] Notificação recebida")
        print("   Title: \(notification.request.content.title)")
        print("   Body: \(notification.request.content.body)")
        print("   Identifier: \(notification.request.identifier)")
        
        // Verifica se o app está em primeiro plano
        let appState = UIApplication.shared.applicationState
        let isForeground = appState == .active
        
        if isForeground {
            print("   📱 App em primeiro plano - mostrando notificação")
        } else {
            print("   🔒 App em background/bloqueado - iOS mostrará notificação automaticamente")
        }
        
        // Mostra banner, som e badge mesmo em primeiro plano
        // Em background, o iOS mostra automaticamente, mas manter a configuração garante que funcione
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    /// Trata quando o usuário toca na notificação
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("👆 [NotificationDelegate] Usuário tocou na notificação")
        print("   Identifier: \(response.notification.request.identifier)")
        print("   Action: \(response.actionIdentifier)")
        
        completionHandler()
    }
}

