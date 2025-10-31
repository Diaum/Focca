//
//  FoccaApp.swift
//  Focca
//
//  Created by Fiasco on 27/10/25.
//

import SwiftUI

@main
struct FoccaApp: App {
    // Inicializa o ScheduleManager quando o app abre
    init() {
        // Acessa o singleton para inicializar o monitoramento
        _ = ScheduleManager.shared
        print("📱 [FoccaApp] App iniciado, ScheduleManager inicializado")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
