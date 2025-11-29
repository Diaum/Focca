import SwiftUI

struct WhiteRoundedBottomPlain: View {
    let isBlocked: Bool
    
    init(isBlocked: Bool = false) {
        self.isBlocked = isBlocked
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 150)
            .fill(
                LinearGradient(
                    colors: isBlocked
                        ? [
                            Color(hex: "181818").opacity(0.8),
                            Color(hex: "")
                        ]
                        : [
                            Color(hex: "EDE7E6").opacity(0.95),
                            Color(hex: "EDE7E6")
                        ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(height: 90)
            .padding(.horizontal, 10)
            .padding(.bottom, 0)
            .clipShape(
                RoundedCorner(radius: 120, corners: [.topLeft, .topRight])
            )
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: -4)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Color(hex: "EDE7E6")
            .ignoresSafeArea()
        VStack {
            Spacer()
            WhiteRoundedBottomPlain()
        }
    }
    .preferredColorScheme(.light)
}


