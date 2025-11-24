import SwiftUI
import FamilyControls
import ManagedSettings

struct OnboardingStep2: View {
    @State private var selection = FamilyActivitySelection()
    @State private var isAuthorized = false
    @State private var showAuthorizationAlert = false
    @Environment(\.presentationMode) var presentationMode
    let didComplete: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F3F0")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    FamilyActivityPicker(selection: $selection)
                        .frame(maxHeight: .infinity)
                    
                    Spacer(minLength: 40)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            let totalItems = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count

                            if totalItems > 0 {
                                if selection.categoryTokens.count > 0 {
                                    Text("\(selection.categoryTokens.count) categoria(s) selecionada(s)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                if selection.applicationTokens.count > 0 {
                                    Text("\(selection.applicationTokens.count) app(s) selecionado(s)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                if selection.webDomainTokens.count > 0 {
                                    Text("\(selection.webDomainTokens.count) site(s) selecionado(s)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Nenhuma seleção")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button(action: {
                            // Verifica se a permissão de Screen Time foi concedida
                            if isAuthorized {
                                saveSelection()
                                didComplete()
                            } else {
                                showAuthorizationAlert = true
                            }
                        }) {
                            Text("Continuar")
                                .fontWeight(.semibold)
                                .foregroundColor(!isAuthorized ? Color(hex: "9E9EA3") : .white)
                                .padding(.horizontal, 24)
                                .frame(height: 40)
                                .background(!isAuthorized ? Color(hex: "DAD7D6") : Color.black)
                                .cornerRadius(20)
                        }
                        .disabled(!isAuthorized)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .preferredColorScheme(.light)
            .onAppear {
                loadSavedSelection()
                checkAuthorizationStatus()
            }
            .alert("Permissão de Tempo de Uso necessária", isPresented: $showAuthorizationAlert) {
                Button("Abrir Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("Você precisa autorizar o acesso ao Tempo de Uso para continuar. Ative nas Configurações.")
            }
        }
    }
    
    private func saveSelection() {
        saveAppsToUserDefaults()
    }
    
    private func saveAppsToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(encoded, forKey: "familyActivitySelection")
        }
    }
    
    private func loadSavedSelection() {
        if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        }
    }
    
    private func checkAuthorizationStatus() {
        let screenTimePermissions = ScreenTimePermissions()
        isAuthorized = screenTimePermissions.isAuthorized()
    }
    
    private func requestAuthorizationIfNeeded() async {
        let screenTimePermissions = ScreenTimePermissions()
        
        // Verifica o status atual
        let status = screenTimePermissions.checkAuthorizationStatus()
        
        // Se não estiver autorizado, solicita permissão
        if status != .approved {
            let granted = await screenTimePermissions.requestAuthorization()
            await MainActor.run {
                isAuthorized = granted
                if !granted {
                    print("⚠️ [OnboardingStep2] Permissão de Screen Time não concedida")
                }
            }
        } else {
            await MainActor.run {
                isAuthorized = true
            }
        }
    }
}

#Preview {
    OnboardingStep2(didComplete: {})
}

