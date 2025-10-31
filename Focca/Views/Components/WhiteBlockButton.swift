import SwiftUI

struct WhiteBlockButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Focca your device")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "1C1C1E"))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    ZStack {
                        // Base suave
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "F9F9F9"),
                                        Color(hex: "EAEAEC")
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            // Simulação de sombra interna sutil
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.8),
                                                Color.black.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.8
                                    )
                            )
                            // Sombra externa bem suave e difusa
                            .shadow(color: Color.white.opacity(0.8), radius: 2, x: -2, y: -2)
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 2, y: 3)
                            // Efeito de leve profundidade (simula sombra interna)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.black.opacity(0.04),
                                                Color.white.opacity(0.3)
                                            ],
                                            startPoint: .bottomTrailing,
                                            endPoint: .topLeading
                                        ),
                                        lineWidth: 1
                                    )
                                    .blur(radius: 1)
                            )
                    }
                )
                .padding(.horizontal, 36)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack {
            Spacer()
            WhiteBlockButton(action: {})
                .padding(.bottom, 80)
        }
    }
    .preferredColorScheme(.light)
}
