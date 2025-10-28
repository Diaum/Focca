import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            // Fundo com gradiente e leve sombra superior
            RoundedRectangle(cornerRadius: 36)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1A1A1A"),
                            Color(hex: "0F0F0F")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.8), radius: 10, x: 0, y: -3)
                .ignoresSafeArea(edges: .bottom)
            
            HStack {
                TabItem(title: "Brick", isSelected: selectedTab == 0)
                    .onTapGesture { selectedTab = 0 }
                
                TabItem(title: "Schedule", isSelected: selectedTab == 1)
                    .onTapGesture { selectedTab = 1 }
                
                TabItem(title: "Activity", isSelected: selectedTab == 2)
                    .onTapGesture { selectedTab = 2 }
                
                TabItem(title: "Settings", isSelected: selectedTab == 3)
                    .onTapGesture { selectedTab = 3 }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .frame(height: 90)
    }
}

struct TabItem: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(isSelected ? .white : Color(hex: "8E8E93"))
            
            Circle()
                .fill(isSelected ? Color.white : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TabBar(selectedTab: .constant(0))
}
