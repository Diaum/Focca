import SwiftUI

struct DarkBlockButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Unfoccus")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    ZStack {
                        // Base com gradiente escuro (parte de cima um pouco mais clara)
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "2A2A2C"),
                                        Color(hex: "151517")
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Realce fino na borda (topo levemente claro -> base escurece)
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.10),
                                        .black.opacity(0.60)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                        
                        // Sombra interna (top highlight)
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.white.opacity(0.20), lineWidth: 2)
                            .blur(radius: 2)
                            .offset(y: -2)
                            .mask(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white, .clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            )
                        
                        // Sombra interna (bottom shadow)
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.black.opacity(0.8), lineWidth: 3)
                            .blur(radius: 3)
                            .offset(y: 3)
                            .mask(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(
                                        LinearGradient(
                                            colors: [.clear, .black],
                                            startPoint: .center,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                    }
                )
                // Relevo externo discreto
                .shadow(color: .black.opacity(0.55), radius: 10, x: 0, y: 6)
                .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: -1)
                .padding(.horizontal, 28)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "181818").ignoresSafeArea()
        VStack {
            Spacer()
            DarkBlockButton(action: {})
            Spacer().frame(height: 80)
        }
    }
    .preferredColorScheme(.dark)
}
