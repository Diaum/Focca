import SwiftUI

struct AwardsView: View {
    @Binding var selectedTab: Int
    let isBlocked: Bool
    @ObservedObject private var awardManager = AwardManager.shared
    @State private var selectedFilter: AwardFilter = .all
    
    init(selectedTab: Binding<Int>, isBlocked: Bool = false) {
        self._selectedTab = selectedTab
        self.isBlocked = isBlocked
    }
    
    let awards: [(id: String, icon: String, title: String, subtitle: String, tint: String)] = [
        ("30_min_focus", "clock.fill", "30 minutos focado", "Fique focado por 30 minutos em uma única sessão", "1C1C1E"),
        ("1_hour_focus", "star.fill", "1 hora focada", "Fique focado por 1 hora em uma única sessão", "FFD700"),
        ("create_goal", "target", "Definidor de Metas", "Crie sua primeira meta", "00A8FF"),
        ("7_day_streak", "flame", "Sequência de 7 dias", "Use o Focca sete dias seguidos com pelo menos 1 hora por dia", "FF6B6B"),
        ("10_hours_total", "hourglass", "10 horas totais", "Acumule dez horas de tempo focado", "0EA5E9"),
        ("15_day_streak", "flame.fill", "Sequência de 15 dias", "Use o Focca quinze dias seguidos com pelo menos 1 hora por dia", "FF4500"),
        ("24_hours_total", "clock.fill", "24 horas totais", "Acumule vinte e quatro horas de tempo focado", "8B5CF6"),
        ("30_day_streak", "flame.fill", "Sequência de 30 dias", "Use o Focca trinta dias seguidos com pelo menos 1 hora por dia", "DC143C"),
        ("72_hours_total", "clock.badge.checkmark.fill", "72 horas totais", "Acumule setenta e duas horas de tempo focado", "4B0082"),
        ("scheduled_session", "calendar.badge.clock", "Sessão agendada", "Inicie uma sessão de foco usando um agendamento", "4F46E5"),
        ("48_hours_total", "clock.badge.fill", "48 horas totais", "Acumule quarenta e oito horas de tempo focado", "9370DB"),
        ("complete_weekly_goal", "calendar.badge.checkmark", "Mestre de Meta Semanal", "Complete uma meta semanal", "007AFF"),
        ("complete_monthly_goal", "calendar.badge.clock.fill", "Mestre de Meta Mensal", "Complete uma meta mensal", "5856D6"),
    ]
    
    var filteredAwards: [(id: String, icon: String, title: String, subtitle: String, tint: String)] {
        let filtered: [(id: String, icon: String, title: String, subtitle: String, tint: String)]
        
        switch selectedFilter {
        case .all:
            filtered = awards
        case .completed:
            filtered = awards.filter { awardManager.isAwardUnlocked($0.id) }
        case .incomplete:
            filtered = awards.filter { !awardManager.isAwardUnlocked($0.id) }
        }
        
        return filtered.sorted { award1, award2 in
            let isUnlocked1 = awardManager.isAwardUnlocked(award1.id)
            let isUnlocked2 = awardManager.isAwardUnlocked(award2.id)
            
            if isUnlocked1 == isUnlocked2 {
                return false
            }
            
            return !isUnlocked1 && isUnlocked2
        }
    }

    var body: some View {
        ZStack {
            (isBlocked
                ? Color(hex: "242424")
                : Color(hex: "d9d4d3"))
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        selectedTab = 3
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                            .frame(width: 44, height: 44)
                            .background(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Conquistas")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 0)
                .padding(.bottom, 12)
                
                AwardFilterView(selectedFilter: $selectedFilter, isBlocked: isBlocked)
                    .padding(.bottom, 22)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(filteredAwards, id: \.id) { award in
                            AwardCard(
                                awardId: award.id,
                                icon: award.icon,
                                title: award.title,
                                subtitle: award.subtitle,
                                tint: Color(hex: award.tint),
                                isBlocked: isBlocked
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 250)
                }
            }
            .padding(.bottom, 105)

            VStack(spacing: 0) {
                Spacer()
                WhiteRoundedBottomPlain(isBlocked: isBlocked)
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -48)
            }
            .zIndex(1)
        }
        .preferredColorScheme(isBlocked ? .dark : .light)
        .onAppear {
            AwardManager.shared.checkAllAwards()
            AwardManager.shared.markAwardsAsViewed()
        }
    }
}

struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView(selectedTab: .constant(2), isBlocked: false)
            .preferredColorScheme(.light)
    }
}

