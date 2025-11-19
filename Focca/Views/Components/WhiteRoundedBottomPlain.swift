import SwiftUI

// Versão sem botão: apenas a base arredondada branca para servir de rodapé visual
struct WhiteRoundedBottomPlain: View {
    let isBlocked: Bool
    
    init(isBlocked: Bool = false) {
        self.isBlocked = isBlocked
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 120)
            .fill(
                LinearGradient(
                    colors: isBlocked
                        ? [
                            Color(hex: "181818"),
                            Color(hex: "").opacity(0.6)
                        ]
                        : [
                            Color(hex: "F9F4F0"),
                            Color(hex: "").opacity(0.9)
                        ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(height: 90)
            .padding(.horizontal, 0)
            .padding(.bottom, 0)
            .clipShape(
                RoundedCorner(radius: 40, corners: [.topLeft, .topRight])
            )
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
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
            WhiteRoundedBottomPlain()
        }
    }
    .preferredColorScheme(.light)
}


