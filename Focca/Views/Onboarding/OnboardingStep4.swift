import SwiftUI

struct OnboardingStep4: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @State private var email = ""
    @State private var showCodeView = false
    @State private var isValidEmail = false
    @State private var savedEmail = ""
    
    var body: some View {
        ZStack {
            if showCodeView {
                OnboardingStep6(email: savedEmail, onBack: {
                    showCodeView = false
                    authViewModel.errorMessage = nil
                })
                .transition(.move(edge: .trailing))
            } else {
                emailInputView
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showCodeView)
    }
    
    private var emailInputView: some View {
        ZStack {
            Color(hex: "ECE8E6")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
<<<<<<< Updated upstream
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
=======
                Spacer()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Crie sua conta")
                            .font(.system(size: 32, weight: .semibold))
>>>>>>> Stashed changes
                            .foregroundColor(Color(hex: "1D1D1F"))
                        
                        Text("Digite seu e-mail para começar")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "7A7A7A"))
                    }
<<<<<<< Updated upstream
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.top, 8)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Retome o controle do seu tempo")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 60)
                
                // 🔹 Imagem do Brick
                Image("focca-rectangle-gray")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 197)
                    .padding(.bottom, 50)
                
                VStack(spacing: 10) {
                    Text("Pegue o seu Focca")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                    
                    Text("Você tem 5 desbloqueios emergenciais caso fique sem o dispositivo.")
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

                        // Marca criação do modo "padrao" no primeiro bloqueio e persiste a seleção
                        if UserDefaults.standard.bool(forKey: "mode_padrao_exists") == false {
                            UserDefaults.standard.set(true, forKey: "mode_padrao_exists")
                            if let encoded = try? JSONEncoder().encode(saved) {
                                UserDefaults.standard.set(encoded, forKey: "mode_padrao_selection")
                            }
                        }
                        // Define o modo ativo e quantidade
                        UserDefaults.standard.set("padrao", forKey: "active_mode_name")
                        UserDefaults.standard.set(saved.applicationTokens.count, forKey: "active_mode_app_count")

                        // Marca o onboarding como completo
                        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
                        UserDefaults.standard.synchronize()
                        
                        // Notifica que o onboarding foi completado
                        NotificationCenter.default.post(name: NSNotification.Name("OnboardingCompleted"), object: nil)

                        // Inicia timer
                        let now = Date()
                        sharedDefaults.set(now, forKey: "blocked_start_date")
                        sharedDefaults.synchronize()
                        
                        // Salva também no standardDefaults para garantir acesso
                        UserDefaults.standard.set(now, forKey: "blocked_start_date")
                        UserDefaults.standard.synchronize()
                        
                        // Registra início de bloqueio por app
                        AppBlockingTracker.shared.startBlocking(selection: saved, startDate: now)
                        
                        // Notifica que o bloqueio iniciou (para o timer iniciar)
                        NotificationCenter.default.post(name: NSNotification.Name("BlockingStarted"), object: nil)

                        // Start Live Activity (no onboarding sempre mostra, pois é o primeiro uso)
                        startLiveActivity(startDate: now)

                        showBlockedView = true
                    }
                }) {
                    Text("Foccar dispositivo")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1D1F"))
=======
                    .padding(.bottom, 40)
                    
                    VStack(spacing: 16) {
                        TextField("seu@email.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .font(.system(size: 17))
                            .foregroundColor(Color(hex: "1D1D1F"))
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(12)
                            .onChange(of: email) { _ in
                                isValidEmail = isValidEmailFormat(email)
                            }
                        
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            sendOtp()
                        }) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Enviar código")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
>>>>>>> Stashed changes
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isValidEmail && !authViewModel.isLoading ? Color.black : Color(hex: "DAD7D6"))
                        .cornerRadius(12)
                        .disabled(!isValidEmail || authViewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
        }
    }
    
    private func sendOtp() {
        let emailTrimmed = email.trimmingCharacters(in: .whitespaces)
        guard isValidEmailFormat(emailTrimmed) else { return }
        
        Task {
            let success = await authViewModel.sendOtp(email: emailTrimmed)
            
            await MainActor.run {
                if success {
                    savedEmail = emailTrimmed
                    authViewModel.errorMessage = nil
                    withAnimation {
                        showCodeView = true
                    }
                }
            }
        }
    }
    
    private func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
