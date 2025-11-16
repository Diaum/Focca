import SwiftUI

struct MonthlyGoalsCard: View {
    let completed: Int
    let isBlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                
                Text("Monthly Goals")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("\(completed)")
                    .font(.system(size: 26, weight: .light, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                Text(completed == 1 ? "Completed" : "Completed")
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
    HStack(spacing: 12) {
        MonthlyGoalsCard(completed: 3, isBlocked: false)
        MonthlyGoalsCard(completed: 8, isBlocked: true)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

