import SwiftUI

struct PrincipalView: View {
    @State private var isBlocked = UserDefaults.standard.bool(forKey: "blocked_by_schedule") || UserDefaults.standard.object(forKey: "blocked_start_date") != nil
    @State private var selectedTab = 0
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    
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
                UnlockedView(isBlocked: $isBlocked, selectedTab: $selectedTab)
            case 2:
                ActivityView(selectedTab: $selectedTab)
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
            // Verifica estado inicial ao abrir o app
            isBlocked = scheduleManager.isBlockedBySchedule || UserDefaults.standard.object(forKey: "blocked_start_date") != nil
        }
    }
}

#Preview {
    PrincipalView()
}

