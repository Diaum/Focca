import SwiftUI

struct ActivityView: View {
    @Binding var selectedTab: Int
        
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("Today")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        
                        Text("0:02")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                    
                    VStack(spacing: 4) {
                        Text("Average")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "8A8A8E"))
                        
                        Text("0:00")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 60)
                
                Text("Activities will appear after your first day using Brick")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "9E9EA3"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                TabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ActivityView(selectedTab: .constant(2))
}


