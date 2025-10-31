import SwiftUI

struct ScheduleListView: View {
    @Binding var selectedTab: Int
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    @State private var schedulesByMode: [String: [ScheduleModel]] = [:]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 120)
                
                // Lista de modos com schedules
                VStack(spacing: 14) {
                    if schedulesByMode.isEmpty {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .frame(height: 64)
                            .overlay(
                                HStack {
                                    Text("No schedules yet")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                            .padding(.horizontal, 16)
                    } else {
                        ForEach(schedulesByMode.keys.sorted(), id: \.self) { mode in
                            let items = schedulesByMode[mode] ?? []
                            ScheduleModeCard(modeName: mode, schedules: items)
                                .padding(.horizontal, 16)
                        }
                    }
                }
                
                Spacer(minLength: 24)
            }
            
            VStack(spacing: 0) {
                Spacer()
                WhiteRoundedBottomPlain()
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, 0)
            }
        }
        .preferredColorScheme(.light)
        .onAppear { reload() }
    }
    
    private func reload() {
        // Carrega todos os schedules válidos e agrupa por modo
        let all = ScheduleManager.shared.loadAllSchedules()
            .filter { $0.isActive && UserDefaults.standard.bool(forKey: "mode_\($0.modeName)_exists") }
        schedulesByMode = Dictionary(grouping: all, by: { $0.modeName })
    }
}

private struct ScheduleModeCard: View {
    let modeName: String
    let schedules: [ScheduleModel]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(modeName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            VStack(spacing: 12) {
                ForEach(schedules) { schedule in
                    HStack(spacing: 10) {
                        Text(daysString(from: schedule.weekdays))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                            .frame(width: 120, alignment: .leading)
                        
                        Text("\(format(schedule.startTime)) - \(format(schedule.endTime))")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "8E8E93"))
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        )
    }
    
    private func format(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
    
    private func daysString(from set: Set<Int>) -> String {
        // 1=Sun ... 7=Sat
        let map: [Int: String] = [1:"S",2:"M",3:"T",4:"W",5:"T",6:"F",7:"S"]
        let ordered = (1...7).filter { set.contains($0) }
        return ordered.map { map[$0] ?? "?" }.joined(separator: " ")
    }
}

#Preview {
    ScheduleListView(selectedTab: .constant(1))
}


