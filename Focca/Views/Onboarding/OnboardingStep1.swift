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
            Color(hex: "E7E2DF")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 80)

                VStack(spacing: 4) {
                    Text("Which apps are distractions?")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)

                Text("We recommend starting with 1–3 apps that you find to occupy too much of your time")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "7D7C80"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 40)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 25, x: 0, y: -4)
                        .ignoresSafeArea(edges: .bottom)

                    VStack {
                        Spacer()
                        
                        Image("onboardingstep1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 400)
                            .padding(.bottom, 10)

                        Button(action: {
                            Task {
                                await requestPermissions()
                            }
                        }) {
                            Text(getButtonText())
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 200)
                                .frame(height: 50)
                                .background(Color(hex: "E7E2DF"))
                                .cornerRadius(25)
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        }
                        .disabled(isRequestingPermission || isRequestingNotification)
                        .padding(.bottom, 50)
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.45)
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
            return "Requesting notification permission..."
        } else if isRequestingPermission {
            return "Requesting permission..."
        } else if !notificationPermissionGranted {
            return "Enable permissions"
        } else {
            return "Select apps to limit"
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

