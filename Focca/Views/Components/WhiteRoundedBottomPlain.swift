import SwiftUI

struct WhiteRoundedBottomPlain: View {
    let isBlocked: Bool
    
    init(isBlocked: Bool = false) {
        self.isBlocked = isBlocked
    }
    
    var body: some View {
        RoundedCorner(radius: 50, corners: [.bottomLeft, .bottomRight])
            .fill(Color(hex: "EDE7E6"))
            .frame(height: 90)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedCorner(radius: 50, corners: [.bottomLeft, .bottomRight])
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "EDE7E6"),
                                Color(hex: "EDE7E6"),
                                Color(hex: "B8B8B8").opacity(0.6),
                                Color(hex: "B8B8B8").opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 3)
            )
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


