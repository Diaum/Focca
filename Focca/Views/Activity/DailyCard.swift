import SwiftUI

struct DailyCard: View {
    let date: Date
    let time: TimeInterval
    let isBlocked: Bool
    
    init(date: Date, time: TimeInterval, isBlocked: Bool = false) {
        self.date = date
        self.time = time
        self.isBlocked = isBlocked
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date).uppercased()
    }
    
    private var formattedTime: String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        return String(format: "%dh\n%02dm", hours, minutes)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(formattedDate)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8A8A8E"))
                .multilineTextAlignment(.center)
            
            Text(formattedTime)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(isBlocked ? Color(hex: "1C1C1C") : Color.white)
        .cornerRadius(16)
        .shadow(color: isBlocked ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    DailyCard(date: Date(), time: 6 * 3600 + 43 * 60)
        .frame(width: 120)
        .padding()
        .background(Color(hex: "F7F7F8"))
}
