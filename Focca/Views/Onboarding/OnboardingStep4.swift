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
                Spacer()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Crie sua conta")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(Color(hex: "1D1D1F"))
                        
                        Text("Digite seu e-mail para começar")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "7A7A7A"))
                    }
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
