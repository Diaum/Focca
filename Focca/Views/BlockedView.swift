import SwiftUI
import ManagedSettings

struct BlockedView: View {
    @Binding var isBlocked: Bool
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A0A")
                .ignoresSafeArea()
                
            
            VStack(spacing: 0) {
                Spacer(minLength: 140)
                
                Text("You've been Bricked for")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8E"))
                
                TimerComponent(isActive: isBlocked)
                    .padding(.bottom, 60)
                
                Image("Focca_Preto")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 350, height: 197)
                    .padding(.bottom, 60)
                
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
                .padding(.bottom, 60)
                
                Spacer()
                
                BlackRoundedBottom(action: {
                    let store = ManagedSettingsStore()
                    store.application.blockedApplications = nil
                    
                    isBlocked = false
                })
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

