import SwiftUI
import FamilyControls
import ManagedSettings
import ActivityKit

struct UnlockedView: View {
    @Binding var isBlocked: Bool
    @Binding var selectedTab: Int
    @State private var showModeSheet = false
    @State private var activeModeName = "-"
    @State private var activeModeCount = 0
    @State private var todayTime: String = "0h 0m"
    @State private var currentActivity: Activity<FoccaWidgetLiveAttributes>?

    private let sharedDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F0ECEB"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
//            .overlay(ReferenceGrid(spacing: 24, color: .red.opacity(0.15)))
            
            VStack(spacing: 0) {
                Spacer(minLength: 145)
                Spacer()
                HStack(spacing: 4) {
                    Text(todayTime)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    
                    Text("today")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "8A8A8E"))
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .padding(.bottom, 60)


                
                Image("Focca_branco")
                
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 350, height: 197)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                    .padding(.bottom, 60)
                
                VStack(spacing: 8) {
                    Button(action: { showModeSheet = true }) {
                        HStack(spacing: 6) {
                            Text("Mode : \(activeModeName)")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "1C1C1E"))
                                .offset(y: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Text("Blocking \(activeModeCount) apps")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .padding(.bottom, 60)
                
                Spacer()
                
                WhiteRoundedBottom(action: {
                    let activeMode = getValidActiveMode()

                    if let data = UserDefaults.standard.data(forKey: "mode_\(activeMode)_selection"),
                       let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                        let store = ManagedSettingsStore()
                        let apps = Set(saved.applicationTokens.compactMap { Application(token: $0) })
                        store.application.blockedApplications = apps
                        
                        let now = Date()
                        sharedDefaults.set(now, forKey: "blocked_start_date")

                        // Start Live Activity
                        startLiveActivity(startDate: now)

                        isBlocked = true
                    }
                })
                    .padding(.bottom, 0)
                
                TabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showModeSheet, onDismiss: {
            let validMode = getValidActiveMode()
            activeModeName = validMode
            activeModeCount = UserDefaults.standard.integer(forKey: "active_mode_app_count")
        }) {
            ModeSelectionSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .onAppear {
            TimerStorage.shared.initializeFirstLaunch()
            updateTodayTime()

            let validMode = getValidActiveMode()
            activeModeName = validMode
            activeModeCount = UserDefaults.standard.integer(forKey: "active_mode_app_count")

            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                DispatchQueue.main.async {
                    self.updateTodayTime()
                }
            }
        }
        .onChange(of: isBlocked) { blocked in
            if !blocked {
                updateTodayTime()
            }
        }
    }
    
    private func updateTodayTime() {
        let totalTime = TimerStorage.shared.getTodayTime()
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        todayTime = String(format: "%dh %dm", hours, minutes)
    }

    private func getValidActiveMode() -> String {

        let savedActiveMode = UserDefaults.standard.string(forKey: "active_mode_name")

        if let savedActiveMode = savedActiveMode,
           !savedActiveMode.isEmpty {
            let modeExists = UserDefaults.standard.bool(forKey: "mode_\(savedActiveMode)_exists")

            if modeExists {
                return savedActiveMode
            } else {
            }
        }

        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let modeKeys = allKeys.filter { $0.hasPrefix("mode_") && $0.hasSuffix("_exists") }

        for key in modeKeys {
            if UserDefaults.standard.bool(forKey: key) {
                let modeName = key.replacingOccurrences(of: "mode_", with: "").replacingOccurrences(of: "_exists", with: "")

                UserDefaults.standard.set(modeName, forKey: "active_mode_name")

                if let data = UserDefaults.standard.data(forKey: "mode_\(modeName)_selection"),
                   let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                    UserDefaults.standard.set(saved.applicationTokens.count, forKey: "active_mode_app_count")
                }

                return modeName
            }
        }

        return "default"
    }

    private func startLiveActivity(startDate: Date) {
        let attributes = FoccaWidgetLiveAttributes()
        let contentState = FoccaWidgetLiveAttributes.ContentState(
            startDate: startDate,
            isActive: true
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            sharedDefaults.set(activity.id, forKey: "live_activity_id")
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
}

#Preview {
    UnlockedView(isBlocked: .constant(false), selectedTab: .constant(0))
}

