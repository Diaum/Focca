import SwiftUI

struct AwardsView: View {
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
                // Header
                HStack {
                    Text("Awards")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        AwardCard(icon: "timer", title: "30 minutes focused", subtitle: "Stay focused for 30 minutes in a single session", tint: Color(hex: "1C1C1E"))
                        AwardCard(icon: "flame", title: "7-day streak", subtitle: "Use Focca seven days in a row", tint: Color(hex: "FF6B6B"))
                        AwardCard(icon: "calendar.badge.clock", title: "Scheduled session", subtitle: "Start a focus session using a schedule", tint: Color(hex: "4F46E5"))
                        AwardCard(icon: "hand.thumbsup", title: "Leave a review", subtitle: "Share your feedback on the App Store", tint: Color(hex: "34C759"))
                        AwardCard(icon: "hourglass", title: "10 hours total", subtitle: "Accumulate ten hours of focused time", tint: Color(hex: "0EA5E9"))
                        AwardCard(icon: "bolt.badge.a", title: "First Live Activity", subtitle: "Start your first Live Activity", tint: Color(hex: "F59E0B"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            
            VStack(spacing: 0) {
                Spacer()
                WhiteRoundedBottomPlain()
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -50)
            }
        }
        .preferredColorScheme(.light)
    }
}

struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView(selectedTab: .constant(2))
            .preferredColorScheme(.light)
    }
}

