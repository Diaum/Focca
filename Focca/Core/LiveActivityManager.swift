import Foundation
import ActivityKit
import UserNotifications

/// Gerencia o ciclo de vida da Live Activity do Focca
struct LiveActivityManager {
    static func startIfSupported(startDate: Date = Date()) {
        if #available(iOS 16.1, *) {
            let auth = ActivityAuthorizationInfo()
            guard auth.areActivitiesEnabled else {
                debugNotify("Live Activities desativadas nas configurações do sistema/capacidades.")
                return
            }
            let attributes = FoccaWidgetLiveAttributes()
            let content = FoccaWidgetLiveAttributes.ContentState(startDate: startDate, isActive: true)
            do {
                _ = try Activity<FoccaWidgetLiveAttributes>.request(attributes: attributes, contentState: content)
                print("🎯 [LiveActivity] Iniciada com sucesso")
            } catch {
                print("❌ [LiveActivity] Erro ao iniciar: \(error)")
                debugNotify("Falha ao iniciar Live Activity: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ [LiveActivity] iOS abaixo de 16.1 não suporta Live Activities")
        }
    }

    static func endAll() {
        if #available(iOS 16.1, *) {
            let activities = Activity<FoccaWidgetLiveAttributes>.activities
            for activity in activities {
                Task { await activity.end(dismissalPolicy: .immediate) }
            }
            print("🛑 [LiveActivity] Encerradas \(activities.count) atividades")
        }
    }

    private static func debugNotify(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Focca — Live Activity"
        content.body = message
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "live_activity_debug_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}


