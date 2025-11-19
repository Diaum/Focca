import SwiftUI

struct DarkBlockButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Desativar Focca")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: "1E1E1F"))
                        
                        // Borda interna superior clara (simula a luz)
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.10),  // Reduzido de 0.20 para 0.10
                                        Color.white.opacity(0.02)   // Reduzido de 0.05 para 0.02
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                            .blur(radius: 0.8)
                            .offset(y: -0.6)
                            .mask(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white, .clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            )
                        
                        // Borda interna inferior escura (simula rebaixo)
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.7),
                                        Color.black.opacity(0.9)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2.2
                            )
                            .blur(radius: 2.5)
                            .offset(y: 2.0)
                            .mask(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(
                                        LinearGradient(
                                            colors: [.clear, .black],
                                            startPoint: .center,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                        
                
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.25),
                                        Color.black.opacity(0.0),
                                        Color.black.opacity(0.25)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .blur(radius: 2)
                    }
                )
                // Efeito de “entalhado” (inset shadow)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.04),  // Reduzido de 0.08 para 0.04
                                    Color.black.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                        .blendMode(.overlay)
                )

                .padding(.horizontal, 28)
        }
        .buttonStyle(.plain)
    }
}

struct DarkBlockButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hex: "181818").ignoresSafeArea()
            VStack {
                Spacer()
                DarkBlockButton(action: {})
                Spacer().frame(height: 80)
            }
        }
        .preferredColorScheme(.dark)
    }
}

