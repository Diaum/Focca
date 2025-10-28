import SwiftUI
import ManagedSettings

struct BlockedView: View {
    @Binding var isBlocked: Bool
    @Binding var selectedTab: Int
    
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
                
                TimerComponent(isActive: isBlocked)
                    .padding(.bottom, 56)
                
                Image("block-rectangle-dark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 210, height: 210)
                    .padding(.bottom, 56)
                
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text("Mode : \(UserDefaults.standard.string(forKey: "active_mode_name") ?? "-")")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Blocking \(UserDefaults.standard.integer(forKey: "active_mode_app_count")) apps")
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
                
                BlackRoundedBottom(action: {})
                    .padding(.bottom, 0)
                
                TabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    BlockedView(isBlocked: .constant(true), selectedTab: .constant(0))
}

