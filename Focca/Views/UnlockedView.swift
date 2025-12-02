import SwiftUI
import FamilyControls
import ManagedSettings
import ActivityKit
import WidgetKit
import CoreNFC

struct UnlockedView: View {
    @Binding var isBlocked: Bool
    @Binding var selectedTab: Int
    @State private var showModeSheet = false
    @State private var showEditMode = false
    @State private var modeToEdit: String?
    @State private var showCreateMode = false
    @State private var activeModeName = "-"
    @State private var activeModeAppCount = 0
    @State private var activeModeCategoryCount = 0
    @State private var todayTime: String = "0h 0m"
    @State private var currentActivity: Activity<FoccaWidgetLiveAttributes>?
    @State private var showGIF = false
    @StateObject private var nfcReader = NFCReaderManager()
    @State private var showNFCError = false
    @State private var nfcErrorMessage = ""

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
            Color(hex: "d9d4d3")
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Text(formattedHours)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    
                    Text(formattedMinutes)
                        .font(.system(size: 18, weight: .light, design: .rounded))
                        .foregroundColor(Color(hex: "1A1A1A"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "F3F0EF"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "D8D3D1"), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                )
                .padding(.top, -80)
                .padding(.bottom, 20)

                AnimatedGIFView(name: "focca-rectangle-white-to-black", duration: 1.5, isAnimating: showGIF)
                    .frame(width: 300, height: 197)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.bottom, 65)
                
                VStack(spacing: 12) {
                    Button(action: { showModeSheet = true }) {
                        HStack(spacing: 6) {
                            Text("Modo:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "1A1A1A"))
                            Text(activeModeName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "1A1A1A"))
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "1A1A1A"))
                                .offset(y: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Text(activeModeDescription)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "4A4A4A"))
                }
                .padding(.bottom, 70)
            }
            .padding(.bottom, 20)
        }
        .overlay(
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .top) {
                    WhiteRoundedBottomPlain()
                    WhiteBlockButton(action: activateCurrentMode)
                        .padding(.horizontal, 36)
                        .offset(y: -28)
                }
                .padding(.bottom, 0)
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -43)
            }
            .padding(.bottom, 40)
            .ignoresSafeArea(edges: .bottom)
        )
        .preferredColorScheme(.light)
        .sheet(isPresented: $showModeSheet, onDismiss: {
            updateActiveModeDisplayInfo()
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
                    updateActiveModeDisplayInfo()
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
            updateActiveModeDisplayInfo()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ModeSaved"))) { _ in
            updateActiveModeDisplayInfo()
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

            updateActiveModeDisplayInfo()

            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                DispatchQueue.main.async {
                    self.updateTodayTime()
                }
            }
        }
        .onChange(of: isBlocked) { blocked in
            if !blocked {
                showGIF = false
                nfcReader.stopReading()
                updateTodayTime()
            }
        }
        .alert("Erro NFC", isPresented: $showNFCError) {
            Button("OK", role: .cancel) {
                nfcErrorMessage = ""
            }
        } message: {
            Text(nfcErrorMessage)
        }
    }
    
    private func updateTodayTime() {
        let totalTime = TimerStorage.shared.getTodayTime()
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        todayTime = String(format: "%dh %dm", hours, minutes)
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
    
    private func updateActiveModeDisplayInfo() {
        let validMode = getValidActiveMode()
        activeModeName = validMode
        
        if let data = UserDefaults.standard.data(forKey: "mode_\(validMode)_selection"),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            activeModeAppCount = saved.applicationTokens.count
            activeModeCategoryCount = saved.categoryTokens.count
        } else {
            activeModeAppCount = 0
            activeModeCategoryCount = 0
        }
    }
    
    private func activateCurrentMode() {
        showGIF = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            proceedWithBlocking()
        }
    }
    
    private func proceedWithBlocking() {
        let activeMode = getValidActiveMode()
        
        if let data = UserDefaults.standard.data(forKey: "mode_\(activeMode)_selection"),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            let store = ManagedSettingsStore()

            if !saved.applicationTokens.isEmpty {
                let apps = Set(saved.applicationTokens.compactMap { Application(token: $0) })
                store.application.blockedApplications = apps
            }

            if !saved.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(saved.categoryTokens)
            }

            if !saved.webDomainTokens.isEmpty {
                let domains = Set(saved.webDomainTokens.compactMap { WebDomain(token: $0) })
                store.webContent.blockedByFilter = .specific(domains)
            }
            
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
                    let totalCount = saved.applicationTokens.count + saved.categoryTokens.count + saved.webDomainTokens.count
                    UserDefaults.standard.set(totalCount, forKey: "active_mode_app_count")
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

