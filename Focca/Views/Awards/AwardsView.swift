import SwiftUI

struct AwardsView: View {
    @Binding var selectedTab: Int
    let isBlocked: Bool
    @ObservedObject private var awardManager = AwardManager.shared
    @State private var selectedFilter: AwardFilter = .all
    
    init(selectedTab: Binding<Int>, isBlocked: Bool = false) {
        self._selectedTab = selectedTab
        self.isBlocked = isBlocked
    }
    
    let awards: [(id: String, icon: String, title: String, subtitle: String, tint: String)] = [
        ("30_min_focus", "clock.fill", "30 minutes focused", "Stay focused for 30 minutes in a single session", "1C1C1E"),
        ("1_hour_focus", "star.fill", "1 hour focused", "Stay focused for 1 hour in a single session", "FFD700"),
        ("7_day_streak", "flame", "7-day streak", "Use Focca seven days in a row with at least 1 hour per day", "FF6B6B"),
        ("10_hours_total", "hourglass", "10 hours total", "Accumulate ten hours of focused time", "0EA5E9"),
        ("15_day_streak", "flame.fill", "15-day streak", "Use Focca fifteen days in a row with at least 1 hour per day", "FF4500"),
        ("24_hours_total", "clock.fill", "24 hours total", "Accumulate twenty-four hours of focused time", "8B5CF6"),
        ("30_day_streak", "flame.fill", "30-day streak", "Use Focca thirty days in a row with at least 1 hour per day", "DC143C"),
        ("72_hours_total", "clock.badge.checkmark.fill", "72 hours total", "Accumulate seventy-two hours of focused time", "4B0082"),
        ("scheduled_session", "calendar.badge.clock", "Scheduled session", "Start a focus session using a schedule", "4F46E5"),
        ("48_hours_total", "clock.badge.fill", "48 hours total", "Accumulate forty-eight hours of focused time", "9370DB"),
    ]
    
    var filteredAwards: [(id: String, icon: String, title: String, subtitle: String, tint: String)] {
        let filtered: [(id: String, icon: String, title: String, subtitle: String, tint: String)]
        
        switch selectedFilter {
        case .all:
            filtered = awards
        case .completed:
            filtered = awards.filter { awardManager.isAwardUnlocked($0.id) }
        case .incomplete:
            filtered = awards.filter { !awardManager.isAwardUnlocked($0.id) }
        }
        
        return filtered.sorted { award1, award2 in
            let isUnlocked1 = awardManager.isAwardUnlocked(award1.id)
            let isUnlocked2 = awardManager.isAwardUnlocked(award2.id)
            
            if isUnlocked1 == isUnlocked2 {
                return false
            }
            
            return !isUnlocked1 && isUnlocked2
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isBlocked 
                    ? [Color(hex: "0A0A0A"), Color(hex: "0A0A0A")]
                    : [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        selectedTab = 3
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                            .frame(width: 44, height: 44)
                            .background(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Awards")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 0)
                .padding(.bottom, 12)
                
                AwardFilterView(selectedFilter: $selectedFilter, isBlocked: isBlocked)
                    .padding(.bottom, 22)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(filteredAwards, id: \.id) { award in
                            AwardCard(
                                awardId: award.id,
                                icon: award.icon,
                                title: award.title,
                                subtitle: award.subtitle,
                                tint: Color(hex: award.tint),
                                isBlocked: isBlocked
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 250)
                }
            }
            .padding(.bottom, 105)

            VStack(spacing: 0) {
                Spacer()
                WhiteRoundedBottomPlain(isBlocked: isBlocked)
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -48)
            }
            .zIndex(1)
        }
        .preferredColorScheme(isBlocked ? .dark : .light)
        .onAppear {
            AwardManager.shared.checkAllAwards()
            AwardManager.shared.markAwardsAsViewed()
        }
    }
}

struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView(selectedTab: .constant(2), isBlocked: false)
            .preferredColorScheme(.light)
    }
}

