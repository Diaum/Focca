import SwiftUI

struct OnboardingStep1: View {
    var body: some View {
        ZStack {
            Color(hex: "F5F3F0")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("Which apps are")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(.black)
                    
                    Text("distractions?")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(.black)
                }
                .padding(.top, 60)
                .padding(.bottom, 8)
                
                Text("We recommend starting with 1-3 apps that you find to occupy too much of your time")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
                        .frame(width: UIScreen.main.bounds.width - 48, height: 360)
                    
                    VStack(spacing: 0) {
                        Image("onboardingstep1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 220)
                            .padding(.top, 80)
                        
                        Button(action: {}) {
                            Text("Select apps to limit")
                                .font(.system(size: 17, weight: .medium, design: .default))
                                .foregroundColor(.black)
                                .frame(width: 200, height: 50)
                                .background(Color(hex: "E5E5EA"))
                                .cornerRadius(25)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                        }
                        .padding(.top, 40)
                    }
                }
                
                Spacer()
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

