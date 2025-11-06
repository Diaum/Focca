import SwiftUI
import ManagedSettings
import ActivityKit
import FamilyControls

struct BlockedView: View {
    @Binding var isBlocked: Bool
    @Binding var selectedTab: Int

    private let sharedDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A0A")
                .ignoresSafeArea()
//                .overlay(ReferenceGrid(spacing: 24, color: .red.opacity(0.15)))
            
            VStack(spacing: 0) {
                Spacer(minLength: 140)
                
                Text("You've been Bricked for")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8E"))
                
                TimerComponent(isActive: isBlocked)
                    .padding(.bottom, 60)
                
                Image("Focca_Preto")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 197)
                    .padding(.bottom, 60)
                
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Mode : \(UserDefaults.standard.string(forKey: "active_mode_name") ?? "-")")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Blocking \(UserDefaults.standard.integer(forKey: "active_mode_app_count")) apps")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8E"))
                }
                .padding(.bottom, 60)
                
                Spacer()
                
                BlackRoundedBottom(action: {
                    // Feature 5: Desativa o schedule do dia se usuário desbloquear antes do fim
                    // Nota: disableScheduleForToday() e manualUnblock() já chamam endBlocking() internamente,
                    // então não precisamos chamar novamente aqui para evitar dupla contagem
                    if let currentSchedule = ScheduleManager.shared.currentSchedule {
                        ScheduleManager.shared.disableScheduleForToday(scheduleId: currentSchedule.id)
                    } else if ScheduleManager.shared.isBlockedBySchedule {
                        // Se há bloqueio por schedule mas não há schedule atual, desbloqueia manualmente
                        ScheduleManager.shared.manualUnblock()
                    } else {
                        // Caso não seja um schedule, precisa desbloquear manualmente e registrar fim
                        // Obtém os apps bloqueados antes de desbloquear
                        var blockedSelection: FamilyActivitySelection?
                        if let modeName = UserDefaults.standard.string(forKey: "active_mode_name"),
                           let data = UserDefaults.standard.data(forKey: "mode_\(modeName)_selection"),
                           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                            blockedSelection = saved
                        } else if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
                                   let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                            blockedSelection = saved
                        }
                        
                        // Finaliza bloqueio por app apenas se não foi chamado por schedule
                        if let selection = blockedSelection {
                            AppBlockingTracker.shared.endBlocking(selection: selection, endDate: Date())
                        }
                    }
                    
                    // Desbloqueia os apps
                    let store = ManagedSettingsStore()
                    store.application.blockedApplications = nil

                    if let startDate = sharedDefaults.object(forKey: "blocked_start_date") as? Date {
                        TimerStorage.shared.splitOvernightTime(from: startDate, to: Date())
                    }
                    sharedDefaults.removeObject(forKey: "blocked_start_date")

                    // Stop Live Activity
                    stopLiveActivity()

                    isBlocked = false
                })
                    .padding(.bottom, 0)
                
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, 0)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func stopLiveActivity() {
        Task {
            for activity in Activity<FoccaWidgetLiveAttributes>.activities {
                await activity.end(
                    .init(state: activity.content.state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }

            sharedDefaults.removeObject(forKey: "live_activity_id")
        }
    }
}

#Preview {
    BlockedView(isBlocked: .constant(true), selectedTab: .constant(0))
}

