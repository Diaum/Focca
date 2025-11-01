import SwiftUI

struct PrincipalView: View {
    private let appGroupDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
    @State private var isBlocked = UserDefaults.standard.bool(forKey: "blocked_by_schedule") || UserDefaults.standard.object(forKey: "blocked_start_date") != nil || (UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard).object(forKey: "blocked_start_date") != nil
    @State private var selectedTab = 0
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            switch selectedTab {
            case 0:
                if isBlocked || scheduleManager.isBlockedBySchedule {
                    BlockedView(isBlocked: $isBlocked, selectedTab: $selectedTab)
                } else {
                    UnlockedView(isBlocked: $isBlocked, selectedTab: $selectedTab)
                }
            case 1:
                ActivityView(selectedTab: $selectedTab)
            case 2:
                AwardsView(selectedTab: $selectedTab)
            case 3:
                SettingsView(selectedTab: $selectedTab)
            default:
                UnlockedView(isBlocked: $isBlocked, selectedTab: $selectedTab)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScheduleActivated"))) { _ in
            isBlocked = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScheduleDeactivated"))) { _ in
            isBlocked = false
        }
        .onChange(of: scheduleManager.isBlockedBySchedule) { blocked in
            isBlocked = blocked
        }
        .onAppear {
            // Verifica estado inicial ao abrir o app (padrão + app group)
            let stdBlocked = UserDefaults.standard.object(forKey: "blocked_start_date") != nil
            let groupBlocked = appGroupDefaults.object(forKey: "blocked_start_date") != nil
            isBlocked = scheduleManager.isBlockedBySchedule || stdBlocked || groupBlocked
            
            // Verifica e ativa schedules que deveriam estar ativos (ativação automática em background)
            // Isso garante que mesmo se a notificação não for processada, o schedule será ativado ao abrir o app
            scheduleManager.checkSchedules()
            
            // Verifica e inicia Live Activity pendente (se schedule foi ativado em background)
            LiveActivityManager.checkAndStartPendingLiveActivity()
        }
        .onChange(of: scenePhase) { newPhase in
            // Quando o app volta ao foreground, verifica e inicia Live Activity pendente
            if newPhase == .active {
                LiveActivityManager.checkAndStartPendingLiveActivity()
            }
        }
    }
}

#Preview {
    PrincipalView()
}

