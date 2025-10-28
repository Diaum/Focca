import SwiftUI

struct WhiteRoundedBottom: View {
    let action: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 70)
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
                .frame(height: 80)
                .padding(.horizontal, 0)
                .padding(.bottom, 0)
                .clipShape(
                    RoundedCorner(radius: 10, corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
                )
            
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
            WhiteRoundedBottom(action: {})
        }
    }
    .preferredColorScheme(.light)
}

