import SwiftUI
import FamilyControls

struct OnboardingStep1: View {
    @State private var showStep2 = false
    @State private var showStep3 = false
    @State private var isRequestingPermission = false
    
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
                    
                    Text("Esconda todos os apps que roumbam sua atencão e volte a viver")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "7A7A7A"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 50)
                }
                .padding(.bottom, 80)
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                Button(action: {
                    Task {
                        await requestScreenTimePermission()
                    }
                }) {
                    ZStack {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1D1D1F")))
                        } else {
                            Text("Permitir bloqueio")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(hex: "1D1D1F"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(28)
                    .contentShape(Rectangle())
                }
                .disabled(isRequestingPermission)
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
                
                WhiteRoundedBottomPlain()
            }
        }
        .fullScreenCover(isPresented: $showStep2) {
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
    
    private func requestScreenTimePermission() async {
        await MainActor.run {
            isRequestingPermission = true
        }
        
        let screenTimePermissions = ScreenTimePermissions()
        let status = screenTimePermissions.checkAuthorizationStatus()
        
        if status != .approved {
            let granted = await screenTimePermissions.requestAuthorization()
            await MainActor.run {
                isRequestingPermission = false
                if granted {
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
