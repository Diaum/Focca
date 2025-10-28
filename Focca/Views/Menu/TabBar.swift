import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
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
        .frame(height: 60)
        .background(
            Group {
                if colorScheme == .dark {
                    Color(hex: "0F0F0F")
                } else {
                    LinearGradient(
                        colors: [Color(hex: "F5F5F7"), Color(hex: "")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        )
    }
}

struct TabItem: View {
    let title: String
    let isSelected: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(isSelected ? (colorScheme == .dark ? .white : .black) : Color(hex: "9E9EA3"))
            
            Circle()
                .fill(isSelected ? (colorScheme == .dark ? Color.white : Color.black) : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TabBar(selectedTab: .constant(0))
}
