import SwiftUI
import FamilyControls
import ManagedSettings
import ActivityKit

struct OnboardingStep6: View {
    @State private var showBlockedView = false
    @State private var currentActivity: Activity<FoccaWidgetLiveAttributes>?

    private let sharedDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
    
    var body: some View {
        ZStack {
            Color(hex: "ECE8E6")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                Text("Você está pronto para\nrecuperar seu tempo?")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color(hex: "1D1D1F"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                
                Image("focca-rectangle-gray")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 197)
                    .padding(.bottom, 50)
                
                VStack(spacing: 10) {
                    Text("Pegue seu Focca")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                    
                    Text("Esconda todos os apps que roumbam sua atencão")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "7A7A7A"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 50)
                }
                .padding(.bottom, 80)
                
                Spacer()
                
                Button(action: {
                    if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
                       let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data),
                       saved.applicationTokens.count > 0 {
                        let store = ManagedSettingsStore()
                        let apps = Set(saved.applicationTokens.compactMap { Application(token: $0) })
                        store.application.blockedApplications = apps

                        if UserDefaults.standard.bool(forKey: "mode_default_exists") == false {
                            UserDefaults.standard.set(true, forKey: "mode_default_exists")
                            if let encoded = try? JSONEncoder().encode(saved) {
                                UserDefaults.standard.set(encoded, forKey: "mode_default_selection")
                            }
                        }
                        UserDefaults.standard.set("padrão", forKey: "active_mode_name")
                        UserDefaults.standard.set(saved.applicationTokens.count, forKey: "active_mode_app_count")

                        let now = Date()
                        sharedDefaults.set(now, forKey: "blocked_start_date")
                        sharedDefaults.synchronize()
                        
                        UserDefaults.standard.set(now, forKey: "blocked_start_date")
                        UserDefaults.standard.synchronize()
                        
                        AppBlockingTracker.shared.startBlocking(selection: saved, startDate: now)
                        
                        NotificationCenter.default.post(name: NSNotification.Name("BlockingStarted"), object: nil)

                        startLiveActivity(startDate: now)

                        showBlockedView = true
                    }
                }) {
                    Text("Permitir bloqueio")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(28)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showBlockedView) {
            PrincipalView()
        }
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
            print("✅ Live Activity iniciada com sucesso! ID: \(activity.id)")
        } catch {
            print("❌ Erro ao iniciar Live Activity: \(error.localizedDescription)")
        }
    }
}

#Preview {
    OnboardingStep6()
}
