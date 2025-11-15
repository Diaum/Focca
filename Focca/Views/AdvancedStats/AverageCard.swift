import SwiftUI

struct AverageCard: View {
    let averageTime: TimeInterval
    let isBlocked: Bool
    
    private var formattedTime: String {
        let hours = Int(averageTime) / 3600
        let minutes = (Int(averageTime) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh\n%dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Average per Day")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
            
            Spacer()
            
            Text(formattedTime)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                .shadow(color: Color.black.opacity(isBlocked ? 0.3 : 0.04), radius: 3, x: 0, y: 1)
        )
    }
}

#Preview {
    let time1: TimeInterval = 2 * 3600 + 30 * 60
    let time2: TimeInterval = 1 * 3600 + 15 * 60
    
    return HStack(spacing: 12) {
        AverageCard(averageTime: time1, isBlocked: false)
        AverageCard(averageTime: time2, isBlocked: true)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

