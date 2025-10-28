import SwiftUI
import FamilyControls
import ManagedSettings

struct OnboardingStep4: View {
    @State private var showBlockedView = false
    
    var body: some View {
        ZStack {
            // Fundo ligeiramente mais frio e neutro
            Color(hex: "ECE8E6")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 🔹 Back Button no topo
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "1D1D1F"))
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.top, 8)
                
                Spacer()
                
                // 🔹 Título
                VStack(spacing: 4) {
                    Text("You're ready to take")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                    Text("your time back")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                
                // 🔹 Imagem do Brick
                Image("focco_rectangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 240, height: 240)
                    .padding(.bottom, 50)
                
                // 🔹 Subtítulo e texto auxiliar
                VStack(spacing: 10) {
                    Text("Go grab your Brick")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                    
                    Text("You have 5 emergency unbricks, in case you ever are without your device")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "7A7A7A"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 50)
                }
                .padding(.bottom, 80)
                
                Spacer()
                
                // 🔹 Botão - Bloqueia apps via ManagedSettingsStore (Screen Time)
                // blockedApplications remove os apps da tela e impede abertura
                Button(action: {
                    if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
                       let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                        let store = ManagedSettingsStore()
                        let apps = Set(saved.applicationTokens.compactMap { Application(token: $0) })
                        store.application.blockedApplications = apps

                        // Marca criação do modo "default" no primeiro bloqueio e persiste a seleção
                        if UserDefaults.standard.bool(forKey: "mode_default_exists") == false {
                            UserDefaults.standard.set(true, forKey: "mode_default_exists")
                            if let encoded = try? JSONEncoder().encode(saved) {
                                UserDefaults.standard.set(encoded, forKey: "mode_default_selection")
                            }
                        }
                        // Define o modo ativo e quantidade
                        UserDefaults.standard.set("default", forKey: "active_mode_name")
                        UserDefaults.standard.set(saved.applicationTokens.count, forKey: "active_mode_app_count")
                    }
                    showBlockedView = true
                }) {
                    Text("Brick device")
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
}

#Preview {
    OnboardingStep4()
}
