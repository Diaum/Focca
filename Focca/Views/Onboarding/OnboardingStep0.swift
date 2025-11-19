import SwiftUI
import UserNotifications
import UIKit

struct OnboardingStep0: View {
    @State private var showStep1 = false
    @State private var isRequestingPermission = false
    
    var body: some View {
        ZStack {
            Color(hex: "ECE8E6")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Simulated device container
                VStack(spacing: 0) {
                    // Status Bar
                    HStack {
                        Text("14:34")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "signal.bars.3")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            
                            Image(systemName: "wifi")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            
                            Text("91")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            
                            Image(systemName: "battery.100")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "1C1C1E"))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    Spacer(minLength: 40)
                    
                    // Simulated Lock Screen Notification
                    VStack(spacing: 0) {
                        Spacer()
                        
                        VStack(spacing: 0) {
                            // Notification Card
                            HStack(spacing: 12) {
                                // App Icon - Logo do Focca
                                if let appIcon = UIImage.appIcon {
                                    Image(uiImage: appIcon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                } else {
                                    Image("focca-rectangle-black")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                
                                // Notification Content
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Focca")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(hex: "1C1C1E"))
                                    
                                    Text("Seu bloqueio está ativo")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                            
                            Spacer()
                            
                            // Lock Screen Controls
                            HStack {
                                // Flashlight
                                Button(action: {}) {
                                    Circle()
                                        .fill(Color(hex: "F1F0F5"))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "flashlight.off.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(Color(hex: "1C1C1E"))
                                        )
                                }
                                
                                Spacer()
                                
                                // Camera
                                Button(action: {}) {
                                    Circle()
                                        .fill(Color(hex: "F1F0F5"))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(Color(hex: "1C1C1E"))
                                        )
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.bottom, 20)
                            
                            // Home Indicator
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "1C1C1E").opacity(0.3))
                                .frame(width: 134, height: 5)
                                .padding(.bottom, 8)
                        }
                        .frame(height: 400)
                        .padding(.horizontal, 8)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 25, x: 0, y: 12)
                )
                .padding(.horizontal, 24)
                
                // Main Content
                VStack(spacing: 20) {
                    Text("Mantenha-se informado")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    
                    Text("Receba notificações sobre suas sessões de bloqueio, lembretes de schedules e atualizações importantes do Focca.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    
                    Spacer(minLength: 20)
                    
                    // Continue Button
                    Button(action: {
                        Task {
                            await requestNotificationPermission()
                        }
                    }) {
                        Text(isRequestingPermission ? "Solicitando..." : "Permitir notificações")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "1C1C1E"))
                            .cornerRadius(16)
                    }
                    .disabled(isRequestingPermission)
                    .padding(.horizontal, 40)
                    
                    // Not Now Button
                    Button(action: {
                        showStep1 = true
                    }) {
                        Text("Agora não")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "F5F5F5"))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.light)
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

