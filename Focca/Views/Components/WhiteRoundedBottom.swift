import SwiftUI

struct WhiteBlockButton: View {
    let action: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
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
                .shadow(color: Color.gray.opacity(0.9), radius: 12, x: 0, y: -4)
                .clipShape(
                    RoundedCorner(radius: 10, corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
                )
            
            Button(action: action) {
                Text("Brick device")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                    .tracking(0.3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white,
                                            Color(hex: "E5E5EA")
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.05),
                                            Color.white.opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: Color.gray.opacity(0.9), radius: 18, x: 0, y: 8)
                    .shadow(color: Color.white.opacity(0.04), radius: 1, x: 0, y: -1)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 60)
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
            WhiteBlockButton(action: {})
        }
    }
    .preferredColorScheme(.light)
}

