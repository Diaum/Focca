import SwiftUI

struct WeeklyGoalsCard: View {
    let averageTime: TimeInterval
    let isBlocked: Bool
    
    private var hours: Int {
        Int(averageTime) / 3600
    }
    
    private var minutes: Int {
        (Int(averageTime) % 3600) / 60
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                
                Text("Weekly Average")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer(minLength: 0)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                VStack(spacing: 0) {
                    Text("\(hours)h")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    
                    Text(String(format: "%02dm", minutes))
                        .font(.system(size: 26, weight: .light, design: .rounded))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                }
                .multilineTextAlignment(.center)
                
                Text("Per Week")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
            }
            
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
    let time1: TimeInterval = 5 * 3600 + 30 * 60
    let time2: TimeInterval = 12 * 3600 + 15 * 60
    
    return HStack(spacing: 12) {
        WeeklyGoalsCard(averageTime: time1, isBlocked: false)
        WeeklyGoalsCard(averageTime: time2, isBlocked: true)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

