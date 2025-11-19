import SwiftUI
import FamilyControls
import ManagedSettings
import ActivityKit
import WidgetKit

struct UnlockedView: View {
    @Binding var isBlocked: Bool
    @Binding var selectedTab: Int
    @State private var showModeSheet = false
    @State private var showEditMode = false
    @State private var modeToEdit: String?
    @State private var showCreateMode = false
    @State private var activeModeName = "-"
    @State private var activeModeCount = 0
    @State private var todayTime: String = "0h 0m"
    @State private var currentActivity: Activity<FoccaWidgetLiveAttributes>?

    private let sharedDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
    
    private var formattedHours: String {
        let components = todayTime.components(separatedBy: " ")
        return components.first ?? "0h"
    }
    
    private var formattedMinutes: String {
        let components = todayTime.components(separatedBy: " ")
        guard components.count > 1 else { return "00m" }
        let minutesComponent = components[1]
        let minutesValue = minutesComponent.replacingOccurrences(of: "m", with: "")
        if let minutes = Int(minutesValue) {
            return String(format: "%02dm", minutes)
        }
        return minutesComponent
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "ECE8E6"), Color(hex: "F7F7F8")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 145)
                Spacer()
                HStack(spacing: 6) {
                    Text(formattedHours)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    
                    Text(formattedMinutes)
                        .font(.system(size: 18, weight: .light, design: .rounded))
                        .foregroundColor(Color(hex: "1C1C1E"))
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                )
                .padding(.bottom, 52)


                
                Image("focca-rectangle-gray")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 197)
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
                    .padding(.bottom, 60)
                
                VStack(spacing: 8) {
                    Button(action: { showModeSheet = true }) {
                        HStack(spacing: 6) {
                            Text("Modo:")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            Text(activeModeName)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "1C1C1E"))
                                .offset(y: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Text("Bloqueando \(activeModeCount) apps")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .padding(.bottom, 60)
            }
            .padding(.bottom, 200)
        }
        .overlay(
            VStack(spacing: 0) {
                Spacer()
                ZStack(alignment: .top) {
                    WhiteRoundedBottomPlain()
                    WhiteBlockButton(action: activateCurrentMode)
                        .padding(.horizontal, 36)
                        .offset(y: -20)
                }
                .padding(.bottom, 0)
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -12)
            }
            .ignoresSafeArea(edges: .bottom)
        )
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
        .sheet(item: Binding(
            get: { modeToEdit },
            set: { newValue in
                if newValue == nil {
                    let validMode = getValidActiveMode()
                    activeModeName = validMode
                    activeModeCount = UserDefaults.standard.integer(forKey: "active_mode_app_count")
                }
                modeToEdit = newValue
            }
        )) { modeName in
            EditModeView(modeName: modeName)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ModeDataUpdated"))) { _ in
            // Atualiza o contador quando um modo é editado
            let validMode = getValidActiveMode()
            activeModeName = validMode
            activeModeCount = UserDefaults.standard.integer(forKey: "active_mode_app_count")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ModeSaved"))) { _ in
            // Atualiza quando um modo é criado
            let validMode = getValidActiveMode()
            activeModeName = validMode
            activeModeCount = UserDefaults.standard.integer(forKey: "active_mode_app_count")
        }
        .sheet(isPresented: $showCreateMode) {
            CreateModeView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenEditMode"))) { notification in
            if let modeName = notification.object as? String {
                modeToEdit = modeName
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenCreateMode"))) { _ in
            showCreateMode = true
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
    
    private func activateCurrentMode() {
        let activeMode = getValidActiveMode()
        
        if let data = UserDefaults.standard.data(forKey: "mode_\(activeMode)_selection"),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            let store = ManagedSettingsStore()
            let apps = Set(saved.applicationTokens.compactMap { Application(token: $0) })
            store.application.blockedApplications = apps
            
            let now = Date()
            sharedDefaults.set(now, forKey: "blocked_start_date")
            sharedDefaults.synchronize()
            UserDefaults.standard.set(now, forKey: "blocked_start_date")
            UserDefaults.standard.synchronize()
            
            AppBlockingTracker.shared.startBlocking(selection: saved, startDate: now)
            
            let modeName = UserDefaults.standard.string(forKey: "active_mode_name") ?? ""
            let showLiveActivity = UserDefaults.standard.object(forKey: "mode_\(modeName)_show_live_activity") as? Bool ?? true
            if showLiveActivity {
                startLiveActivity(startDate: now)
            }
            
            WidgetCenter.shared.reloadTimelines(ofKind: "FoccaWidgetLive")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                WidgetCenter.shared.reloadTimelines(ofKind: "FoccaWidgetLive")
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("BlockingStarted"), object: nil)
            isBlocked = true
        }
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

        return "padrao"
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

