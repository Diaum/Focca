import SwiftUI

struct WeeklyGoalsCard: View {
    let completed: Int
    let isBlocked: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Weekly Goals")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("\(completed)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                Text(completed == 1 ? "Completed" : "Completed")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
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
        WeeklyGoalsCard(completed: 5, isBlocked: false)
        WeeklyGoalsCard(completed: 12, isBlocked: true)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

