//
//  FoccaApp.swift
//  Focca
//
//  Created by Fiasco on 27/10/25.
//

import SwiftUI
import UserNotifications
import FamilyControls

@main
struct FoccaApp: App {
    // Delegate para notificações (singleton compartilhado)
    private static let notificationDelegate = NotificationDelegate()
    
    // Inicializa o ScheduleManager quando o app abre
    init() {
        // Acessa o singleton para inicializar o monitoramento
        _ = ScheduleManager.shared
        print("📱 [FoccaApp] App iniciado, ScheduleManager inicializado")
        
        // Configura o delegate de notificações ANTES de solicitar permissão
        let center = UNUserNotificationCenter.current()
        center.delegate = FoccaApp.notificationDelegate
        
        print("🔔 [FoccaApp] NotificationDelegate configurado")
        
        // Solicita permissão para notificações
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                print("✅ [FoccaApp] Permissão de notificações concedida")
            } else {
                print("⚠️ [FoccaApp] Permissão de notificações negada")
            }
        }
        
        // Solicita permissão de Screen Time logo no início
        Task {
            let screenTimePermissions = ScreenTimePermissions()
            let granted = await screenTimePermissions.requestAuthorization()
            if granted {
                print("✅ [FoccaApp] Permissão de Screen Time concedida")
            } else {
                print("⚠️ [FoccaApp] Permissão de Screen Time negada ou não determinada")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
