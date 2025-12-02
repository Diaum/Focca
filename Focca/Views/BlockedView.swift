import SwiftUI
import ManagedSettings
import ActivityKit
import FamilyControls
import WidgetKit

struct BlockedView: View {
    @Binding var isBlocked: Bool
    @Binding var selectedTab: Int
    @State private var activeModeName: String = "-"
    @State private var activeModeAppCount: Int = 0
    @State private var activeModeCategoryCount: Int = 0
    @State private var isAnimatingGIF: Bool = false

    private let sharedDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
    
    var body: some View {
        ZStack {    
            Color(hex: "242424")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 80)
                
                
                TimerComponent(isActive: isBlocked)
                    .padding(.bottom, 10)
                
                AnimatedGIFView(name: "focca-rectangle-white-to-black", duration: 1.5, reversed: true, isAnimating: isAnimatingGIF)
                    .frame(width: 300, height: 197)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.bottom, 60)
                
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Text("Modo:")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(activeModeName)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                    }
                    
                    Text(activeModeDescription)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8E"))
                }
                .padding(.bottom, 60)
                
                Spacer()
            }
            .padding(.bottom, 200)
        }
        .overlay(
            VStack(spacing: 0) {
                Spacer()
                ZStack(alignment: .top) {
                    WhiteRoundedBottomPlain(isBlocked: true)
                    DarkBlockButtonNew(action: {
                        isAnimatingGIF = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            if let currentSchedule = ScheduleManager.shared.currentSchedule {
                                ScheduleManager.shared.disableScheduleForToday(scheduleId: currentSchedule.id)
                            } else if ScheduleManager.shared.isBlockedBySchedule {
                                ScheduleManager.shared.manualUnblock()
                            } else {
                                var blockedSelection: FamilyActivitySelection?
                                if let modeName = UserDefaults.standard.string(forKey: "active_mode_name"),
                                   let data = UserDefaults.standard.data(forKey: "mode_\(modeName)_selection"),
                                   let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                                    blockedSelection = saved
                                } else if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
                                          let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                                    blockedSelection = saved
                                }
                                
                                if let selection = blockedSelection {
                                    AppBlockingTracker.shared.endBlocking(selection: selection, endDate: Date())
                                }
                            }
                            
                            AppBlockingTracker.shared.endAllActiveSessions(for: Date(), endDate: Date())
                            
                            let store = ManagedSettingsStore()
                            store.application.blockedApplications = nil
                            store.shield.applicationCategories = nil
                            store.webContent.blockedByFilter = nil

                            if let startDate = sharedDefaults.object(forKey: "blocked_start_date") as? Date {
                                TimerStorage.shared.splitOvernightTime(from: startDate, to: Date())
                            }
                            sharedDefaults.removeObject(forKey: "blocked_start_date")
                            sharedDefaults.synchronize()
                            
                            UserDefaults.standard.removeObject(forKey: "blocked_start_date")
                            UserDefaults.standard.synchronize()
                            
                            stopLiveActivity()
                            
                            WidgetCenter.shared.reloadTimelines(ofKind: "FoccaWidgetLive")
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                WidgetCenter.shared.reloadTimelines(ofKind: "FoccaWidgetLive")
                            }

                            isBlocked = false
                            isAnimatingGIF = false
                        }
                    })
                    .padding(.horizontal, 36)
                    .offset(y: -24)
                }
                .padding(.bottom, 0)
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -3)
            }
            .ignoresSafeArea(edges: .bottom)
        )
        .preferredColorScheme(.dark)
        .onAppear {
            updateModeInfo()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ModeDataUpdated"))) { _ in
            updateModeInfo()
        }
    }
    
    private func updateModeInfo() {
        let modeName = UserDefaults.standard.string(forKey: "active_mode_name") ?? "-"
        activeModeName = modeName.isEmpty ? "-" : modeName
        
        if let data = UserDefaults.standard.data(forKey: "mode_\(modeName)_selection"),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            activeModeAppCount = saved.applicationTokens.count
            activeModeCategoryCount = saved.categoryTokens.count
        } else {
            activeModeAppCount = 0
            activeModeCategoryCount = 0
        }
    }
    
    private var activeModeDescription: String {
        let apps = activeModeAppCount
        let categories = activeModeCategoryCount
        
        if apps > 0 && categories > 0 {
            let appWord = apps == 1 ? "app" : "apps"
            let categoryWord = categories == 1 ? "categoria" : "categorias"
            return "Bloqueando \(apps) \(appWord), \(categories) \(categoryWord)"
        } else if categories > 0 {
            let categoryWord = categories == 1 ? "categoria" : "categorias"
            return "Bloqueando \(categories) \(categoryWord)"
        } else {
            let appWord = apps == 1 ? "app" : "apps"
            return "Bloqueando \(apps) \(appWord)"
        }
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

