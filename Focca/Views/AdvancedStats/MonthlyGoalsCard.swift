import SwiftUI

struct MonthlyGoalsCard: View {
    let completed: Int
    let isBlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Monthly Goals")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
            
            Spacer()
            
            Text("\(completed)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            Text(completed == 1 ? "Completed" : "Completed")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .padding(16)
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

