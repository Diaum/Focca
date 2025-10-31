import SwiftUI

struct AwardCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Capsule()
                .fill(Color(hex: "E5E5EA"))
                .frame(width: 74, height: 26)
                .overlay(
                    Text("Locked")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "6B7280"))
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        )
    }
}

struct AwardCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 14) {
            AwardCard(
                icon: "timer",
                title: "30 minutes focused",
                subtitle: "Stay focused for 30 minutes in a single session",
                tint: Color(hex: "1C1C1E")
            )
            AwardCard(
                icon: "flame",
                title: "7-day streak",
                subtitle: "Use Focca seven days in a row",
                tint: Color(hex: "FF6B6B")
            )
        }
        .padding()
        .background(Color(hex: "F7F7F8"))
        .preferredColorScheme(.light)
    }
}

