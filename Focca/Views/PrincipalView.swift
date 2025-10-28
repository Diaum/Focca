import SwiftUI

struct PrincipalView: View {
    @State private var isBlocked = true
    
    var body: some View {
        Group {
            if isBlocked {
                BlockedView(isBlocked: $isBlocked)
            } else {
                UnlockedView(isBlocked: $isBlocked)
            }
        }
    }
}

#Preview {
    PrincipalView()
}

