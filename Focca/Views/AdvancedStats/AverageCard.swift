import SwiftUI

struct AverageCard: View {
    let averageTime: TimeInterval
    let isBlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                
                Text("Média por Dia")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                
                Spacer()
            }
            
            Spacer()
            
            AverageTimeDisplayView(time: averageTime, isBlocked: isBlocked)
            
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

private struct AverageTimeDisplayView: View {
    let time: TimeInterval
    let isBlocked: Bool
    
    var body: some View {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        VStack(spacing: 0) {
            if hours > 0 {
                HStack(spacing: 0) {
                    Text("\(hours)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    Text("h")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                }
                HStack(spacing: 0) {
                    Text("\(minutes)")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    Text("m")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                }
            } else {
                HStack(spacing: 0) {
                    Text("\(minutes)")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    Text("m")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                }
            }
        }
        .multilineTextAlignment(.center)
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

