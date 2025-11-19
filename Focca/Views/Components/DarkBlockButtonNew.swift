import SwiftUI

struct DarkBlockButtonNew: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Desativar Focca")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "2C2C2E"),
                                        Color(hex: "1E1E1F")
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.1),
                                                Color.black.opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.8
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .shadow(color: Color.white.opacity(0.05), radius: 2, x: -1, y: -1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.black.opacity(0.2),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .bottomTrailing,
                                            endPoint: .topLeading
                                        ),
                                        lineWidth: 1
                                    )
                                    .blur(radius: 1)
                            )
                    }
                )
                .padding(.horizontal, 36)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "0A0A0A")
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            DarkBlockButtonNew(action: {})
                .padding(.bottom, 80)
        }
    }
    .preferredColorScheme(.dark)
}

