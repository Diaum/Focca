import SwiftUI

struct OnboardingStep4: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @State private var email = ""
    @State private var showCodeView = false
    @State private var isValidEmail = false
    @State private var savedEmail = ""
    @State private var showEmailInput = false
    @FocusState private var isEmailFieldFocused: Bool
    
    var body: some View {
        ZStack {
            if showCodeView {
                OnboardingStep5(email: savedEmail, onBack: {
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
                Spacer()
                
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text("Entre para acessar\nsuas configurações")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(Color(hex: "1D1D1F"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    
                    VStack(spacing: 16) {
                        if !showEmailInput {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showEmailInput = true
                                }
                            }) {
                                HStack {
                                    Text("Entrar com e-mail")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(Color(hex: "1D1D1F"))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(hex: "1D1D1F"))
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            .disabled(authViewModel.isLoading)
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                        
                        if showEmailInput {
                            VStack(spacing: 16) {
                                TextField(
                                    "",
                                    text: $email,
                                    prompt: Text("Seu melhor email")
                                        .foregroundColor(Color(hex: "ccc"))
                                )
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .font(.system(size: 17))
                                .foregroundColor(Color(hex: "111"))
                                .focused($isEmailFieldFocused)
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(12)
                                .onChange(of: email) { _ in
                                    isValidEmail = isValidEmailFormat(email)
                                }
                                .padding(.horizontal, 24)
                                .task(id: showEmailInput) {
                                    if showEmailInput {
                                        try? await Task.sleep(nanoseconds: 400_000_000)
                                        isEmailFieldFocused = true
                                    }
                                }
                                
                                if let error = authViewModel.errorMessage {
                                    Text(error)
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                        .transition(.opacity)
                                }
                                
                                Button(action: {
                                    sendOtp()
                                }) {
                                    ZStack {
                                        if authViewModel.isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("Enviar código")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(isValidEmail && !authViewModel.isLoading ? Color(hex: "1D1D1F") : Color(hex: "DAD7D6"))
                                    .cornerRadius(12)
                                }
                                .contentShape(Rectangle())
                                .disabled(!isValidEmail || authViewModel.isLoading)
                                .padding(.horizontal, 24)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: showEmailInput)
                    .onChange(of: showEmailInput) { newValue in
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                isEmailFieldFocused = true
                            }
                        }
                    }
                }
                .padding(.bottom, 100)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Ao continuar, você concorda com nossos")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8E8E93"))
                    
                    HStack(spacing: 4) {
                        Button(action: {}) {
                            Text("Termos de Serviço")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "1D1D1F"))
                                .underline()
                        }
                        
                        Text("e")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "8E8E93"))
                        
                        Button(action: {}) {
                            Text("Política de Privacidade")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "1D1D1F"))
                                .underline()
                        }
                    }
                }
                .padding(.bottom, 40)
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
