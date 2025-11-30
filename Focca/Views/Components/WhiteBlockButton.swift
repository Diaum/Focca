import SwiftUI

struct WhiteBlockButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Ativar o Focca")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(hex: "1A1A1A"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    ZStack {
                        // Base com fundo fosco - mesma cor do fundo principal
                        Capsule()
                            .fill(Color(hex: "d9d4d3"))
                        
                        // Borda interna: branco na metade superior, preto na metade inferior
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.6),
                                        Color.black.opacity(0.2),
                                        Color.black.opacity(0.2)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                    }
                    // Sombra externa difusa e suave
                    .shadow(
                        color: Color.white.opacity(0.6),
                        radius: 4,
                        x: -2,
                        y: -2
                    )
                    // Sombra inferior com profundidade
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 3
                    )
                    // Sombra adicional para efeito de flutuação
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: 12,
                        x: 0,
                        y: 6
                            )
                )
                .padding(.horizontal, 36)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "d9d4d3")
        .ignoresSafeArea()
        
        VStack {
            Spacer()
            WhiteBlockButton(action: {})
                .padding(.bottom, 80)
        }
    }
    .preferredColorScheme(.light)
}
