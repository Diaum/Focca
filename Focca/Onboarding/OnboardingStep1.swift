import SwiftUI

struct OnboardingStep1: View {
    var body: some View {
        ZStack {
            // Fundo bege claro
            Color(hex: "E7E2DF")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 80)

                // Título
                VStack(spacing: 4) {
                    Text("Which apps are distractions?")
                        .font(.custom("SF Pro Display", size: 38).weight(.semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)

                // Subtítulo
                Text("We recommend starting with 1–3 apps that you find to occupy too much of your time")
                    .font(.custom("SF Pro Text", size: 16))
                    .foregroundColor(Color(hex: "7D7C80"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 40)

                Spacer()

                // Parte branca inferior (painel fixo)
                ZStack {
                    // Fundo branco com borda arredondada apenas no topo
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 25, x: 0, y: -4)
                        .ignoresSafeArea(edges: .bottom)

                    VStack {
                        Spacer()
                        
                        // Ícones
                        Image("onboardingstep1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 220)
                            .padding(.bottom, 40)

                        // Botão
                        Button(action: {}) {
                            Text("Select apps to limit")
                                .font(.custom("SF Pro Rounded", size: 15).weight(.medium))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(hex: "E7E2DF"))
                                .cornerRadius(25)
                                .padding(.horizontal, 60)
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        }
                        .padding(.bottom, 50)
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.45) // ocupa parte inferior
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingStep1()
}
