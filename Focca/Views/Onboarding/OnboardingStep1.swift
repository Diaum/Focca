import SwiftUI
import FamilyControls

struct OnboardingStep1: View {
    @State private var showStep2 = false
    @State private var showStep3 = false
    @State private var isRequestingPermission = false
    @State private var isRequestingNotification = false
    @State private var notificationPermissionGranted = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 120)
                
                VStack(spacing: 16) {
                    Text("Quais apps te distraem?")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, 32)
                    
                    Text("Comece selecionando de 1 a 3 apps que mais tomam o seu tempo. Vamos bloquear quando for a hora de focar.")
                        .font(.system(size: 17))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 36)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 25, x: 0, y: -6)
                        .ignoresSafeArea(edges: .bottom)
                    
                    VStack(spacing: 32) {
                        Image("onboardingstep1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 420)
                            .padding(.top, 40)
                        
                        Button(action: {
                            Task {
                                await requestPermissions()
                            }
                        }) {
                            Text(getButtonText())
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(hex: "1C1C1E"))
                                .cornerRadius(18)
                        }
                        .disabled(isRequestingPermission || isRequestingNotification)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 44)
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.5)
            }
        }
        .sheet(isPresented: $showStep2) {
            OnboardingStep2(didComplete: {
                showStep2 = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showStep3 = true
                }
            })
        }
        .fullScreenCover(isPresented: $showStep3) {
            OnboardingStep3()
        }
    }
    
    private func getButtonText() -> String {
        if isRequestingNotification {
            return "Solicitando permissão de notificações..."
        } else if isRequestingPermission {
            return "Solicitando permissão..."
        } else {
            return "Escolher apps"
        }
    }
    
    private func requestPermissions() async {
        // Primeiro, verifica se precisa pedir permissão de notificações
        let notificationGranted = UserDefaults.standard.bool(forKey: "notification_permission_granted")
        
        if !notificationGranted {
            // Verifica o status atual de notificações
            let notificationStatus = await NotificationManager.shared.checkAuthorizationStatus()
            
            if notificationStatus != .authorized {
                isRequestingNotification = true
                let granted = await NotificationManager.shared.requestAuthorization()
                await MainActor.run {
                    isRequestingNotification = false
                    notificationPermissionGranted = granted
                    UserDefaults.standard.set(granted, forKey: "notification_permission_granted")
                }
            } else {
                await MainActor.run {
                    notificationPermissionGranted = true
                }
            }
        } else {
            await MainActor.run {
                notificationPermissionGranted = true
            }
        }
        
        // Depois, pede permissão de Screen Time
        isRequestingPermission = true
        
        let screenTimePermissions = ScreenTimePermissions()
        let status = screenTimePermissions.checkAuthorizationStatus()
        
        if status != .approved {
            let granted = await screenTimePermissions.requestAuthorization()
            await MainActor.run {
                isRequestingPermission = false
                if granted {
                    showStep2 = true
                } else {
                    showStep2 = true
                }
            }
        } else {
            await MainActor.run {
                isRequestingPermission = false
                showStep2 = true
            }
        }
    }
}

#Preview {
    OnboardingStep1()
}

