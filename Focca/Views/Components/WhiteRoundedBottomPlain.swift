import SwiftUI

struct WhiteRoundedBottomPlain: View {
    let isBlocked: Bool
    
    init(isBlocked: Bool = false) {
        self.isBlocked = isBlocked
    }
    
    var body: some View {
        RoundedCorner(radius: 80, corners: [.bottomLeft, .bottomRight])
            .fill(Color(hex: "EDE7E6"))
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedCorner(radius: 80, corners: [.bottomLeft, .bottomRight])
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "EDE7E6"),
                                Color(hex: "EDE7E6"),
                                Color(hex: "8A8A8A"),
                                Color(hex: "8A8A8A")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .blur(radius: 2)
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


