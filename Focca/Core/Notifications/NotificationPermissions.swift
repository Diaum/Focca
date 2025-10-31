import Foundation
import UserNotifications

/// Componente responsável pelo gerenciamento de permissões de notificações
struct NotificationPermissions {
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// Solicita permissão para enviar notificações
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }
    
    /// Verifica o status de autorização atual
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Verifica se as notificações estão autorizadas
    func isAuthorized() async -> Bool {
        let status = await checkAuthorizationStatus()
        return status == .authorized
    }
}

