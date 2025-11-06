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
                            if selection.applicationTokens.count > 0 {
                                Text("\(selection.applicationTokens.count)/50 apps selected")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                if selection.applicationTokens.count > 50 {
                                    Text("⚠️ Maximum 50 apps allowed")
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                }
                            } else if selection.categoryTokens.count > 0 {
                                Text("0/50 apps selected")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text("⚠️ Deselect category → select apps individually")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                            } else {
                                Text("0/50 apps selected")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if selection.applicationTokens.count <= 50 {
                                // Verifica se a permissão de Screen Time foi concedida
                                if isAuthorized {
                                    saveSelection()
                                    didComplete()
                                } else {
                                    showAuthorizationAlert = true
                                }
                            }
                        }) {
                            Text("Next")
                                .fontWeight(.semibold)
                                .foregroundColor((selection.applicationTokens.count > 50 || !isAuthorized) ? Color(hex: "9E9EA3") : .white)
                                .padding(.horizontal, 24)
                                .frame(height: 40)
                                .background((selection.applicationTokens.count > 50 || !isAuthorized) ? Color(hex: "DAD7D6") : Color.black)
                                .cornerRadius(20)
                        }
                        .disabled(selection.applicationTokens.count > 50 || !isAuthorized)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .onAppear {
                loadSavedSelection()
                checkAuthorizationStatus()
                Task {
                    await requestAuthorizationIfNeeded()
                }
            }
            .alert("Screen Time Permission Required", isPresented: $showAuthorizationAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You need to authorize Screen Time access to continue. Please enable it in Settings.")
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

