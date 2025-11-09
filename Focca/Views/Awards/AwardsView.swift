import SwiftUI

enum AwardFilter: String, CaseIterable {
    case all = "All"
    case completed = "Completed"
    case incomplete = "Incomplete"
}

struct AwardsView: View {
    @Binding var selectedTab: Int
    @ObservedObject private var awardManager = AwardManager.shared
    @State private var selectedFilter: AwardFilter = .all
    
    let awards: [(id: String, icon: String, title: String, subtitle: String, tint: String)] = [
        ("30_min_focus", "timer", "30 minutes focused", "Stay focused for 30 minutes in a single session", "1C1C1E"),
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
        switch selectedFilter {
        case .all:
            return awards
        case .completed:
            return awards.filter { awardManager.isAwardUnlocked($0.id) }
        case .incomplete:
            return awards.filter { !awardManager.isAwardUnlocked($0.id) }
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Awards")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                .allowsHitTesting(false)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AwardFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedFilter == filter ? .white : Color(hex: "1C1C1E"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedFilter == filter ? Color(hex: "1C1C1E") : Color.white)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(filteredAwards, id: \.id) { award in
                            AwardCard(
                                awardId: award.id,
                                icon: award.icon,
                                title: award.title,
                                subtitle: award.subtitle,
                                tint: Color(hex: award.tint)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 250)
                }
            }
            .padding(.bottom, 105)
            .clipped()

            VStack(spacing: 0) {
                Spacer()
                WhiteRoundedBottomPlain()
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -18)
            }
            .zIndex(1)
        }
        .preferredColorScheme(.light)
        .clipped()
        .onAppear {
            AwardManager.shared.checkAllAwards()
        }
    }
}

struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView(selectedTab: .constant(2))
            .preferredColorScheme(.light)
    }
}

