import SwiftUI

// Versão sem botão: apenas a base arredondada branca para servir de rodapé visual
struct WhiteRoundedBottomPlain: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 120)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(hex: "")
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(height: 120)
            .padding(.horizontal, 0)
            .padding(.bottom, 0)
            .clipShape(
                RoundedCorner(radius: 8, corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
            )
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


