import SwiftUI
import UserNotifications

struct OnboardingStep0: View {
    @State private var showStep1 = false
    @State private var isRequestingPermission = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Status Bar
                HStack {
                    Text("14:34")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "signal.bars.3")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        
                        Image(systemName: "wifi")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        
                        Text("91")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "battery.100")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Simulated Lock Screen Notification
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Notification Card
                        HStack(spacing: 12) {
                            // App Icon
                            ZStack {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                                
                                Text("A")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            // Notification Content (simulated with lines)
                            VStack(alignment: .leading, spacing: 4) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: "2C2C2E"))
                                    .frame(width: 120, height: 8)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: "2C2C2E"))
                                    .frame(width: 180, height: 6)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: "2C2C2E"))
                                    .frame(width: 160, height: 6)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "1C1C1E"))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 40)
                        
                        Spacer()
                        
                        // Lock Screen Controls
                        HStack {
                            // Flashlight
                            Button(action: {}) {
                                Circle()
                                    .fill(Color(hex: "2C2C2E"))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "flashlight.off.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            Spacer()
                            
                            // Camera
                            Button(action: {}) {
                                Circle()
                                    .fill(Color(hex: "2C2C2E"))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                        
                        // Home Indicator
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 134, height: 5)
                            .padding(.bottom, 8)
                    }
                    .frame(height: 400)
                    
                    Spacer()
                }
                
                // Main Content
                VStack(spacing: 16) {
                    Text("Get Notified About Your Blocking Sessions")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("Get notified about your app blocking sessions, schedule reminders, and important updates.")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Continue Button
                    Button(action: {
                        Task {
                            await requestNotificationPermission()
                        }
                    }) {
                        Text(isRequestingPermission ? "Requesting..." : "Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(isRequestingPermission)
                    .padding(.horizontal, 40)
                    
                    // Not Now Button
                    Button(action: {
                        showStep1 = true
                    }) {
                        Text("Not Now")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "2C2C2E"))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .padding(.top, 40)
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showStep1) {
            OnboardingStep1()
        }
    }
    
    private func requestNotificationPermission() async {
        isRequestingPermission = true
        
        let granted = await NotificationManager.shared.requestAuthorization()
        
        await MainActor.run {
            isRequestingPermission = false
            if granted {
                UserDefaults.standard.set(true, forKey: "notification_permission_granted")
            } else {
                UserDefaults.standard.set(false, forKey: "notification_permission_granted")
            }
            showStep1 = true
        }
    }
}

#Preview {
    OnboardingStep0()
}

