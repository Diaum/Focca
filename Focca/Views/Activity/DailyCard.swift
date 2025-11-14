import SwiftUI

struct DailyCard: View {
    let date: Date
    let time: TimeInterval
    let isBlocked: Bool
    var onTap: (() -> Void)? = nil
    
    init(date: Date, time: TimeInterval, isBlocked: Bool = false, onTap: (() -> Void)? = nil) {
        self.date = date
        self.time = time
        self.isBlocked = isBlocked
        self.onTap = onTap
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date).uppercased()
    }
    
    private var hours: Int {
        Int(time) / 3600
    }
    
    private var minutes: Int {
        (Int(time) % 3600) / 60
    }
    
    // Verifica se o dia tem 0h 0m (sem uso)
    private var isZeroTime: Bool {
        time == 0
    }
    
    // Verifica se não chegou a 1 minuto
    private var isLessThanOneMinute: Bool {
        time > 0 && time < 60
    }
    
    // Determina se o card deve ser cinza
    private var shouldShowGray: Bool {
        isZeroTime || isLessThanOneMinute
    }
    
    // Cor de fundo do card
    private var cardBackgroundColor: Color {
        if isBlocked {
            return Color(hex: "1C1C1C")
        } else if isZeroTime {
            // Cinza mais claro para 0h 0m
            return Color(hex: "F5F5F5")
        } else if isLessThanOneMinute {
            // Cinza para menos de 1 minuto
            return Color(hex: "E5E5E5")
        } else {
            return Color.white
        }
    }
    
    // Cor do texto de horas e minutos
    private var timeTextColor: Color {
        if isBlocked {
            return .white
        } else if shouldShowGray {
            return Color(hex: "8A8A8E")
        } else {
            return Color(hex: "1C1C1E")
        }
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(spacing: 6) {
                Text(formattedDate)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8A8A8E"))
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 0) {
                    Text("\(hours)h")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(timeTextColor)
                    
                    Text(String(format: "%02dm", minutes))
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(timeTextColor)
                }
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: isBlocked ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DailyCard(date: Date(), time: 6 * 3600 + 43 * 60)
        .frame(width: 120)
        .padding()
        .background(Color(hex: "F7F7F8"))
}
