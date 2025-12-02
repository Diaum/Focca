import SwiftUI
import FamilyControls

struct ScreenTimeRequiredView: View {
    @ObservedObject private var screenTimeMonitor = ScreenTimeMonitor.shared
    @State private var isRequestingPermission = false
    
    var body: some View {
        ZStack {
            Color(hex: "d9d4d3")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Ícone
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "1C1C1E"))
                    .padding(.bottom, 20)
                
                // Título
                Text("Screen Time Necessário")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                    .multilineTextAlignment(.center)
                
                // Descrição
                VStack(spacing: 12) {
                    Text("O Focca precisa do Screen Time para funcionar corretamente.")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(Color(hex: "4A4A4A"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("Por favor, ative o Screen Time nas Configurações do iOS para continuar usando o app.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "6A6A6A"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Botão de ação
                VStack(spacing: 16) {
                    Button(action: {
                        openSettings()
                    }) {
                        Text("Abrir Configurações")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "1C1C1E"))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                    
                    Button(action: {
                        Task {
                            await requestPermission()
                        }
                    }) {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1C1C1E")))
                                .frame(height: 20)
                        } else {
                            Text("Verificar Novamente")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "1C1C1E"))
                        }
                    }
                    .disabled(isRequestingPermission)
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            screenTimeMonitor.checkAuthorizationStatus()
        }
        .onChange(of: screenTimeMonitor.isScreenTimeAuthorized) { authorized in
            if authorized {
                print("✅ [ScreenTimeRequiredView] Screen Time reativado!")
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func requestPermission() async {
        await MainActor.run {
            isRequestingPermission = true
        }
        
        let screenTimePermissions = ScreenTimePermissions()
        let granted = await screenTimePermissions.requestAuthorization()
        
        await MainActor.run {
            isRequestingPermission = false
            screenTimeMonitor.checkAuthorizationStatus()
        }
    }
}

#Preview {
    ScreenTimeRequiredView()
}

