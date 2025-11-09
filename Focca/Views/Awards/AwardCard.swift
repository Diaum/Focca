import SwiftUI

struct AwardCard: View {
    let awardId: String
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let isBlocked: Bool
    @ObservedObject private var awardManager = AwardManager.shared

    var isUnlocked: Bool {
        awardManager.isAwardUnlocked(awardId)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(isUnlocked ? 0.2 : 0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Capsule()
                .fill(isUnlocked ? Color(hex: "34C759") : (isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA")))
                .frame(width: 74, height: 26)
                .overlay(
                    Text(isUnlocked ? "Unlocked" : "Locked")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isUnlocked ? .white : (isBlocked ? Color(hex: "8A8A8E") : Color(hex: "6B7280")))
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                .shadow(color: Color.black.opacity(isBlocked ? 0.3 : 0.04), radius: 3, x: 0, y: 1)
        )
    }
}

struct AwardCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 14) {
            AwardCard(
                awardId: "30_min_focus",
                icon: "timer",
                title: "30 minutes focused",
                subtitle: "Stay focused for 30 minutes in a single session",
                tint: Color(hex: "1C1C1E"),
                isBlocked: false
            )
            AwardCard(
                awardId: "7_day_streak",
                icon: "flame",
                title: "7-day streak",
                subtitle: "Use Focca seven days in a row",
                tint: Color(hex: "FF6B6B"),
                isBlocked: false
            )
        }
        .padding()
        .background(Color(hex: "F7F7F8"))
        .preferredColorScheme(.light)
    }
}

