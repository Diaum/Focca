import SwiftUI

struct StreakCard: View {
    let streak: Int
    let isBlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                
                Text("Sequência Atual")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("\(streak)")
                    .font(.system(size: 26, weight: .light, design: .rounded))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                
                Text(streak == 1 ? "dia" : "dias")
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
                .fill(isBlocked ? Color(hex: "1C1C1C") : Color(hex: "e4e0e0"))
                .shadow(color: Color.black.opacity(isBlocked ? 0.3 : 0.04), radius: 3, x: 0, y: 1)
        )
    }
}

#Preview {
    HStack(spacing: 12) {
        StreakCard(streak: 7, isBlocked: false)
        StreakCard(streak: 15, isBlocked: true)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

