import SwiftUI
import FamilyControls
import ManagedSettings

struct UnlockedView: View {
    @Binding var isBlocked: Bool
    @Binding var selectedTab: Int
    @State private var showModeSheet = false
    @State private var activeModeName = UserDefaults.standard.string(forKey: "active_mode_name") ?? "-"
    @State private var activeModeCount = UserDefaults.standard.integer(forKey: "active_mode_app_count")
    @State private var todayTime: String = "0h 0m"
    
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
                    let activeMode = UserDefaults.standard.string(forKey: "active_mode_name") ?? "default"
                    
                    if let data = UserDefaults.standard.data(forKey: "mode_\(activeMode)_selection"),
                       let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                        let store = ManagedSettingsStore()
                        let apps = Set(saved.applicationTokens.compactMap { Application(token: $0) })
                        store.application.blockedApplications = apps
                        
                        let now = Date()
                        UserDefaults.standard.set(now, forKey: "blocked_start_date")
                        
                        isBlocked = true
                    }
                })
                    .padding(.bottom, 0)
                
                TabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showModeSheet, onDismiss: {
            activeModeName = UserDefaults.standard.string(forKey: "active_mode_name") ?? "-"
            activeModeCount = UserDefaults.standard.integer(forKey: "active_mode_app_count")
        }) {
            ModeSelectionSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .onAppear {
            TimerStorage.shared.initializeFirstLaunch()
            updateTodayTime()
            
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
}

#Preview {
    UnlockedView(isBlocked: .constant(false), selectedTab: .constant(0))
}

