import SwiftUI

struct BlockedView: View {
    @State private var selectedTab = 0
    @State private var elapsedTime = "4h 27m 54s" // Exemplo — você pode conectar a um timer real
    
    var body: some View {
        ZStack {
            Color(hex: "0F0F0F") // Fundo mais profundo e neutro
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                // 🔹 Texto superior
                Text("You’ve been Bricked for")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .padding(.bottom, 8)
                
                // 🔹 Tempo central
                Text(elapsedTime)
                    .font(.system(size: 54, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                // 🔹 Imagem do Brick
                Image("block-rectangle-dark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 210, height: 210)
                    .padding(.bottom, 36)
                
                // 🔹 Modo e subtítulo
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Mode : Focused")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .offset(y: 1)
                    }
                    
                    Text("Blocking 6 apps")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .padding(.bottom, 60)
                
                // 🔹 Botão principal
                Button(action: {
                    // ação para unbrick
                }) {
                    Text("Unbrick device")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color(hex: "1A1A1A"))
                                .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 4)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                
                Spacer()
                
                // 🔹 TabBar inferior
                TabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    BlockedView()
}
