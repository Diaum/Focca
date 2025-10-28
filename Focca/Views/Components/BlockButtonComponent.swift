import SwiftUI

struct BlockButtonComponent: View {
    let action: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "222"),
                            Color(hex: "")
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(height: 120)
                .padding(.horizontal, 0)
                .padding(.bottom, 0)
                .shadow(color: .black.opacity(0.9), radius: 12, x: 0, y: -4)
                .clipShape(
                    RoundedCorner(radius: 10, corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
                )
            
            Button(action: action) {
                Text("Unbrick device")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .tracking(0.3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "222222"),
                                            Color(hex: "161616")
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.05),
                                            Color.black.opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: .black.opacity(0.9), radius: 18, x: 0, y: 8)
                    .shadow(color: Color.white.opacity(0.04), radius: 1, x: 0, y: -1)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 10)
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 10
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ZStack {
        Color(hex: "181818").ignoresSafeArea()
        
        VStack {
            Spacer()
            BlockButtonComponent(action: {})
        }
    }
    .preferredColorScheme(.dark)
}

