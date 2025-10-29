import SwiftUI

struct BlackRoundedBottom: View {
    let action: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 120)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "181818"),
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
            
            DarkBlockButton(action: action)
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

