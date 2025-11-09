import Foundation
import ActivityKit
import UserNotifications
import UIKit

/// Gerencia o ciclo de vida da Live Activity do Focca
struct LiveActivityManager {
    /// Verifica se o app está em foreground
    private static var isAppInForeground: Bool {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return scene.activationState == .foregroundActive
        }
        return UIApplication.shared.applicationState == .active
    }
    
    static func startIfSupported(startDate: Date = Date()) {
        // Verifica se o app está em foreground antes de tentar iniciar
        guard isAppInForeground else {
            print("⏸️ [LiveActivity] App não está em foreground. Marca para iniciar quando app entrar em foreground.")
            // Marca que precisa iniciar Live Activity quando app entrar em foreground
            let userDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
            userDefaults.set(true, forKey: "pending_live_activity_start")
            userDefaults.set(startDate, forKey: "pending_live_activity_start_date")
            return
        }
        
        startLiveActivityNow(startDate: startDate)
    }
    
    /// Inicia a Live Activity imediatamente (deve ser chamado apenas quando app está em foreground)
    static func startLiveActivityNow(startDate: Date = Date()) {
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
                
                // Limpa flags pendentes
                let userDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
                userDefaults.removeObject(forKey: "pending_live_activity_start")
                userDefaults.removeObject(forKey: "pending_live_activity_start_date")
            } catch {
                print("❌ [LiveActivity] Erro ao iniciar: \(error)")
                debugNotify("Falha ao iniciar Live Activity: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ [LiveActivity] iOS abaixo de 16.1 não suporta Live Activities")
        }
    }
    
    /// Verifica e inicia Live Activity pendente (chamado quando app entra em foreground)
    /// Verifica a preferência do modo antes de iniciar
    static func checkAndStartPendingLiveActivity() {
        let userDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
        
        guard userDefaults.bool(forKey: "pending_live_activity_start") else {
            return
        }
        
        guard let startDate = userDefaults.object(forKey: "pending_live_activity_start_date") as? Date else {
            userDefaults.removeObject(forKey: "pending_live_activity_start")
            return
        }
        
        // Verifica se o modo permite Live Activity
        let modeName = UserDefaults.standard.string(forKey: "active_mode_name") ?? ""
        let showLiveActivity = UserDefaults.standard.object(forKey: "mode_\(modeName)_show_live_activity") as? Bool ?? true
        if showLiveActivity {
            print("🔄 [LiveActivity] Iniciando Live Activity pendente...")
            startLiveActivityNow(startDate: startDate)
        } else {
            print("⏸️ [LiveActivity] Live Activity desativada para o modo '\(modeName)'")
            userDefaults.removeObject(forKey: "pending_live_activity_start")
            userDefaults.removeObject(forKey: "pending_live_activity_start_date")
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


