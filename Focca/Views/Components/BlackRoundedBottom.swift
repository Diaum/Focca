import SwiftUI

struct BlackRoundedBottom: View {
    let action: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 70)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black,
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
                    RoundedCorner(radius: 40, corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
                )
            
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "fff")
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            BlackRoundedBottom(action: {})
        }
    }
    .preferredColorScheme(.dark)
}

