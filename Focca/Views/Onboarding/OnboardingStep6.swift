import SwiftUI

struct OnboardingStep6: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @State private var code: [String] = Array(repeating: "", count: 8)
    @State private var focusedIndex = 0
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
                
                VStack(spacing: 32) {
                    Text("Your code")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                        .padding(.top, 40)
                    
                    HStack(spacing: 12) {
                        ForEach(0..<8, id: \.self) { index in
                            CodeDigitBox(
                                text: code[index],
                                isFocused: focusedIndex == index,
                                onTap: {
                                    focusedIndex = index
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Text("Enter the 8-digit code sent to\n\(email)")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "1D1D1F"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    Button(action: {
                        Task {
                            await authViewModel.sendOtp(email: email)
                        }
                    }) {
                        Text("Generate new code")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "1D1D1F"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "E5E5E5"))
                            .cornerRadius(12)
                    }
                    .disabled(authViewModel.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                
                Spacer()
                
                NumericKeypad(
                    onDigitTapped: { digit in
                        if focusedIndex < 8 {
                            code[focusedIndex] = digit
                            if focusedIndex < 7 {
                                focusedIndex += 1
                            } else {
                                verifyCode()
                            }
                        }
                    },
                    onDelete: {
                        if focusedIndex > 0 && code[focusedIndex].isEmpty {
                            focusedIndex -= 1
                        }
                        if focusedIndex >= 0 && focusedIndex < 8 {
                            code[focusedIndex] = ""
                        }
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showStep5) {
            OnboardingStep5()
        }
        .onChange(of: code) { _ in
            let fullCode = code.joined()
            if fullCode.count == 8 {
                verifyCode()
            }
        }
    }
    
    private func verifyCode() {
        let fullCode = code.joined()
        guard fullCode.count == 8 else { return }
        
        Task {
            let success = await authViewModel.verifyOtp(email: email, code: fullCode)
            if success {
                showStep5 = true
            }
        }
    }
}

struct CodeDigitBox: View {
    let text: String
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(text.isEmpty ? Color(hex: "E5E5E5") : Color.white)
                .frame(width: 50, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color(hex: "1D1D1F") : Color.clear, lineWidth: 2)
                )
            
            if !text.isEmpty {
                Text(text)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "1D1D1F"))
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct NumericKeypad: View {
    let onDigitTapped: (String) -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                KeypadButton(title: "1", subtitle: nil, action: { onDigitTapped("1") })
                KeypadButton(title: "2", subtitle: "ABC", action: { onDigitTapped("2") })
                KeypadButton(title: "3", subtitle: "DEF", action: { onDigitTapped("3") })
            }
            
            HStack(spacing: 12) {
                KeypadButton(title: "4", subtitle: "GHI", action: { onDigitTapped("4") })
                KeypadButton(title: "5", subtitle: "JKL", action: { onDigitTapped("5") })
                KeypadButton(title: "6", subtitle: "MNO", action: { onDigitTapped("6") })
            }
            
            HStack(spacing: 12) {
                KeypadButton(title: "7", subtitle: "PQRS", action: { onDigitTapped("7") })
                KeypadButton(title: "8", subtitle: "TUV", action: { onDigitTapped("8") })
                KeypadButton(title: "9", subtitle: "WXYZ", action: { onDigitTapped("9") })
            }
            
            HStack(spacing: 12) {
                Spacer()
                KeypadButton(title: "0", subtitle: nil, action: { onDigitTapped("0") })
                KeypadDeleteButton(action: onDelete)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .background(Color(hex: "2C2C2E"))
    }
}

struct KeypadButton: View {
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color(hex: "3A3A3C"))
            .cornerRadius(12)
        }
    }
}

struct KeypadDeleteButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "delete.backward")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color(hex: "3A3A3C"))
                .cornerRadius(12)
        }
    }
}

