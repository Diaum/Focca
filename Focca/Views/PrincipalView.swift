import SwiftUI

struct PrincipalView: View {
    @State private var isBlocked = true
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            switch selectedTab {
            case 0:
                if isBlocked {
                    BlockedView(isBlocked: $isBlocked, selectedTab: $selectedTab)
                } else {
                    UnlockedView(isBlocked: $isBlocked, selectedTab: $selectedTab)
                }
            case 1:
                UnlockedView(isBlocked: $isBlocked, selectedTab: $selectedTab)
            case 2:
                ActivityView(selectedTab: $selectedTab)
            case 3:
                UnlockedView(isBlocked: $isBlocked, selectedTab: $selectedTab)
            default:
                UnlockedView(isBlocked: $isBlocked, selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    PrincipalView()
}

