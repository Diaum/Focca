import SwiftUI

struct OnboardingStep4Code: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @State private var code = ""
    @State private var showStep5 = false
    let email: String
    let onBack: (() -> Void)?
    
    init(email: String, onBack: (() -> Void)? = nil) {
        self.email = email
        self.onBack = onBack
    }
    
    var body: some View {
        ZStack {
            Color(hex: "ECE8E6")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        if let onBack = onBack {
                            onBack()
                        } else {
                            showStep5 = false
                        }
                    }) {
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
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Verifique seu e-mail")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(Color(hex: "1D1D1F"))
                        
                        Text("Digite o código enviado para\n\(email)")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "7A7A7A"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 40)
                    
                    VStack(spacing: 16) {
                        TextField("000000", text: $code)
                            .keyboardType(.numberPad)
                            .font(.system(size: 24, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(hex: "1D1D1F"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(12)
                            .onChange(of: code) { newValue in
                                code = String(newValue.prefix(6))
                            }
                        
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            Task {
                                let success = await authViewModel.verifyOtp(email: email, code: code)
                                if success {
                                    showStep5 = true
                                }
                            }
                        }) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Confirmar")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(code.count == 6 && !authViewModel.isLoading ? Color.black : Color(hex: "DAD7D6"))
                        .cornerRadius(12)
                        .disabled(code.count != 6 || authViewModel.isLoading)
                        
                        Button(action: {
                            Task {
                                await authViewModel.sendOtp(email: email)
                            }
                        }) {
                            Text("Reenviar código")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "7A7A7A"))
                        }
                        .disabled(authViewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showStep5) {
            OnboardingStep5()
        }
    }
}

