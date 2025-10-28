import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: Int
    
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
        .background(Color(hex: ""))
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
