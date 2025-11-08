import SwiftUI

struct ActivityView: View {
    @Binding var selectedTab: Int
    let isBlocked: Bool
    @State private var showModeSheet = false
    @State private var showDailyDetail = false
    @State private var selectedDate: Date?
    @State private var selectedTime: TimeInterval = 0
    @State private var todayTime: String = "0h 0m"
    @State private var averageTime: String = "0h 0m"
    @State private var dailyCards: [(date: Date, time: TimeInterval)] = []
    @State private var lastLoggedAppCount: Int = -1 // Para evitar logs repetidos
    // Permite injetar dados no Preview para mostrar cards
    let initialDailyCards: [(date: Date, time: TimeInterval)]?
    
    init(selectedTab: Binding<Int>, isBlocked: Bool = false, initialDailyCards: [(date: Date, time: TimeInterval)]? = nil) {
        self._selectedTab = selectedTab
        self.isBlocked = isBlocked
        self.initialDailyCards = initialDailyCards
    }
        
    var body: some View {
        ZStack {
            LinearGradient(
                colors: isBlocked 
                    ? [Color(hex: "0A0A0A"), Color(hex: "0A0A0A")]
                    : [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
//            .overlay(ReferenceGrid(spacing: 24, color: .red.opacity(0.15)))
            
            VStack(spacing: 0) {
                Spacer(minLength: 30)
                
                HStack(spacing: 80) {
                    VStack(spacing: 4) {
                        Text("Today")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8A8A8E"))
                        
                        Text(todayTime)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    }
                    
                    VStack(spacing: 4) {
                        Text("Average")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8A8A8E"))
                        
                        Text(averageTime)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    }
                }
                .padding(.top, 0)
                .padding(.bottom, 60)
                
                if dailyCards.isEmpty {
                    Text("Activities will appear after your first day using Brick")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "9E9EA3"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 40)

                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ], spacing: 10) {
                            ForEach(dailyCards, id: \.date) { card in
                                DailyCard(
                                    date: card.date,
                                    time: card.time,
                                    isBlocked: isBlocked,
                                    onTap: {
                                        print("🖱️ [ActivityView] DailyCard clicado - date: \(card.date), time: \(card.time)")
                                        // Define os valores primeiro de forma síncrona
                                        selectedDate = card.date
                                        selectedTime = card.time
                                        print("✅ [ActivityView] selectedDate definido: \(selectedDate?.description ?? "nil")")
                                        print("✅ [ActivityView] selectedTime definido: \(selectedTime)")
                                        // Aciona o fullScreenCover imediatamente após definir os valores
                                        showDailyDetail = true
                                        print("✅ [ActivityView] showDailyDetail = true")
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                

                                
                WhiteRoundedBottomPlain(isBlocked: isBlocked)
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -50)

                
            }
            
        }
        .sheet(isPresented: $showModeSheet) {
            ModeSelectionSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .fullScreenCover(isPresented: $showDailyDetail) {
            Group {
                if let date = selectedDate {
                    DailyDetailView(date: date, totalTime: selectedTime, isBlocked: isBlocked, selectedTab: $selectedTab)
                        .onAppear {
                            print("✅ [ActivityView] DailyDetailView apareceu - date: \(date), time: \(selectedTime)")
                        }
                        .onDisappear {
                            // Limpa a seleção quando a view é fechada
                            selectedDate = nil
                            selectedTime = 0
                        }
                } else {
                    // Fallback: mostra uma view vazia se selectedDate for nil
                    VStack {
                        Text("Erro: selectedDate é nil")
                            .foregroundColor(.red)
                            .padding()
                        Text("showDailyDetail: \(showDailyDetail ? "true" : "false")")
                            .foregroundColor(.red)
                            .padding()
                    }
                    .background(Color.white)
                    .onAppear {
                        print("⚠️ [ActivityView] Fallback apareceu - selectedDate é nil, showDailyDetail: \(showDailyDetail)")
                        // Se selectedDate ainda for nil, fecha a view imediatamente
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if selectedDate == nil {
                                print("❌ [ActivityView] Fechando fullScreenCover porque selectedDate é nil")
                                showDailyDetail = false
                            }
                        }
                    }
                }
            }
            .onAppear {
                print("📱 [ActivityView] fullScreenCover apareceu - showDailyDetail: \(showDailyDetail), selectedDate: \(selectedDate != nil ? "definido" : "nil")")
            }
        }
        .onChange(of: showDailyDetail) { newValue in
            print("🔄 [ActivityView] showDailyDetail mudou para: \(newValue)")
        }
        .onChange(of: selectedDate) { newValue in
            print("🔄 [ActivityView] selectedDate mudou para: \(newValue?.description ?? "nil")")
        }
        .preferredColorScheme(isBlocked ? .dark : .light)
        .onAppear {
            if let injected = initialDailyCards {
                // Usa os dados de preview quando fornecidos
                dailyCards = injected
            } else {
                loadActivityData()
            }
            updateTodayTime()
            
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                DispatchQueue.main.async {
                    self.updateTodayTime()
                }
            }
        }
    }
    
    private func loadActivityData() {
        dailyCards = TimerStorage.shared.getAllDailyTimes()
        
        let avgTime = TimerStorage.shared.getAverageTime()
        let hours = Int(avgTime) / 3600
        let minutes = (Int(avgTime) % 3600) / 60
        averageTime = String(format: "%dh %dm", hours, minutes)
    }
    
    private func updateTodayTime() {
        let totalTime = TimerStorage.shared.getTodayTime()
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        todayTime = String(format: "%dh %dm", hours, minutes)
        
        // Log para verificar quantos apps bloqueados têm tempo salvo hoje (apenas quando mudar)
        let today = Date()
        let appDetails = AppBlockingTracker.shared.getAppBlockingDetails(for: today)
        let currentAppCount = appDetails.count
        
        // Só loga se o número de apps mudou ou se ainda não foi logado
        if currentAppCount != lastLoggedAppCount {
            lastLoggedAppCount = currentAppCount
            if appDetails.isEmpty {
                print("📱 [ActivityView] Hoje: Nenhum app bloqueado com tempo salvo")
            } else {
                print("📱 [ActivityView] Hoje: \(appDetails.count) apps bloqueados com tempo salvo (total: \(Int(totalTime / 60))m)")
            }
        }
    }
}

#Preview {
    // Gera 10 cards de dias anteriores para visualização no Preview
    let calendar = Calendar.current
    let samples: [(date: Date, time: TimeInterval)] = (0..<15).compactMap { offset in
        if let date = calendar.date(byAdding: .day, value: -offset, to: Date()) {
            // Ex.: 45min, 60min, 75min, 90min, 105min
            let mins = 45 + offset * 15
            return (date: date, time: TimeInterval(mins * 60))
        }
        return nil
    }
    return ActivityView(selectedTab: .constant(2), initialDailyCards: samples)
}


