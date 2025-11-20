import SwiftUI

struct OnboardingStep5: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @State private var code = ""
    @State private var showStep6 = false
    @FocusState private var isCodeFieldFocused: Bool
    @State private var timeRemaining = 59
    @State private var timer: Timer?
    @State private var canResend = false
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
                Spacer()
                
                VStack(spacing: 32) {
                    Text("Seu código")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                    
                    GeometryReader { geometry in
                        let totalSpacing: CGFloat = 8 * 7
                        let availableWidth = geometry.size.width - 48
                        let boxWidth = min((availableWidth - totalSpacing) / 8, 38)
                        let boxHeight = boxWidth * 1.3
                        
                        HStack(spacing: 8) {
                            ForEach(0..<8, id: \.self) { index in
                                CodeDigitBox(
                                    text: index < code.count ? String(code[code.index(code.startIndex, offsetBy: index)]) : "",
                                    isFocused: isCodeFieldFocused && index == code.count,
                                    width: boxWidth,
                                    height: boxHeight
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 65)
                    .padding(.horizontal, 24)
                    
                    Text("Digite o código de 8 dígitos enviado para\n\(email)")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                    
                    if let error = authViewModel.errorMessage {
                        Text(translateError(error))
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    if !canResend {
                        Text("Você pode gerar um novo código em \(formatTime(timeRemaining))")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    } else {
                        Button(action: {
                            Task {
                                let success = await authViewModel.sendOtp(email: email)
                                if success {
                                    resetTimer()
                                }
                            }
                        }) {
                            Text("Gerar novo código")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "1D1D1F"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(hex: "E5E5E5"))
                                .cornerRadius(12)
                        }
                        .disabled(authViewModel.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                .padding(.top, 60)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showStep6) {
            OnboardingStep6()
        }
        .overlay(
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFieldFocused)
                .opacity(0)
                .frame(width: 0, height: 0)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isCodeFieldFocused = true
            }
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: code) { newValue in
            let filtered = newValue.filter { $0.isNumber }
            code = String(filtered.prefix(8))
            
            if code.count == 8 {
                verifyCode()
            }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timeRemaining = 59
        canResend = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canResend = true
                timer.invalidate()
                self.timer = nil
            }
        }
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func resetTimer() {
        startTimer()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private func translateError(_ error: String) -> String {
        let lowercased = error.lowercased()
        
        if lowercased.contains("invalid") || lowercased.contains("código inválido") {
            return "Código inválido. Tente novamente."
        }
        
        if lowercased.contains("expired") || lowercased.contains("expirado") {
            return "Código expirado. Solicite um novo."
        }
        
        if lowercased.contains("too many") || lowercased.contains("muitas") {
            return "Muitas tentativas. Aguarde um momento."
        }
        
        if lowercased.contains("network") || lowercased.contains("rede") {
            return "Erro de conexão. Verifique sua internet."
        }
        
        return "Erro ao verificar código. Tente novamente."
    }
    
    private func verifyCode() {
        guard code.count == 8 else { return }
        
        Task {
            let success = await authViewModel.verifyOtp(email: email, code: code)
            if success {
                showStep6 = true
            }
        }
    }
}

struct CodeDigitBox: View {
    let text: String
    let isFocused: Bool
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(text.isEmpty ? Color(hex: "E5E5E5") : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color(hex: "1D1D1F") : Color.clear, lineWidth: 2)
                )
            
            if !text.isEmpty {
                Text(text)
                    .font(.system(size: min(width * 0.6, 24), weight: .semibold))
                    .foregroundColor(Color(hex: "1D1D1F"))
            }
        }
        .frame(width: width, height: height)
    }
}
