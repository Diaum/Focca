import SwiftUI

struct WhiteRoundedBottomPlain: View {
    let isBlocked: Bool
    
    init(isBlocked: Bool = false) {
        self.isBlocked = isBlocked
    }
    
    var body: some View {
        let bgColor = isBlocked ? Color(hex: "242424") : Color(hex: "d9d4d3")
        
        return ZStack {
            RoundedCorner(radius: .infinity, corners: [.bottomLeft, .bottomRight])
                .fill(bgColor)
                .frame(height: 90)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedCorner(radius: .infinity, corners: [.bottomLeft, .bottomRight])
                        .stroke(
                            LinearGradient(
                                colors: [
                                    bgColor,
                                    bgColor,
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
            
            LinearGradient(
                colors: [
                    bgColor.opacity(1.0),
                    bgColor.opacity(0.8),
                    bgColor.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Color(hex: "d9d4d3")
            .ignoresSafeArea()
        VStack {
            Spacer()
            WhiteRoundedBottomPlain()
        }
    }
    .preferredColorScheme(.light)
}


