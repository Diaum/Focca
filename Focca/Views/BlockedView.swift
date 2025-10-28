import SwiftUI
import ManagedSettings

struct BlockedView: View {
    @Binding var isBlocked: Bool
    @Binding var selectedTab: Int
    @State private var elapsedTime = "4h 27m 54s"
    
    var body: some View {
        ZStack {
            Color(hex: "181818")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                Text("You've been Bricked for")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8E"))
                    .padding(.bottom, 10)
                
                Text(elapsedTime)
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 56)
                
                Button(action: {
                    isBlocked = false
                }) {
                    Image("block-rectangle-dark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 210, height: 210)
                }
                .padding(.bottom, 56)
                
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
                        .foregroundColor(Color(hex: "8A8A8E"))
                }
                .padding(.bottom, 100)
                
                DarkBlockButton(action: {
                    let store = ManagedSettingsStore()
                    store.application.blockedApplications = nil
                    isBlocked = false
                })
                
                Spacer()
                
                TabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    BlockedView(isBlocked: .constant(true), selectedTab: .constant(0))
}

