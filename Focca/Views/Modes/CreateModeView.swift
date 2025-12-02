import SwiftUI
import FamilyControls

struct CreateModeView: View {
    @State private var modeName: String = ""
    @State private var selection = FamilyActivitySelection()
    @State private var showAppPicker = false
    @Environment(\.presentationMode) var presentationMode
    // Novo: agendamento simples (dias e horários)
    @State private var isScheduled: Bool = false
    @State private var selectedWeekdays: Set<Int> = [] // 1=Sun ... 7=Sat (Calendar.component)
    @State private var startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showLiveActivity: Bool = true // Por padrão ativado
    
    // Feature 1: Valida se schedule está ativo, deve ter pelo menos 1 dia selecionado
    // Feature 4: Valida se não há conflito com schedules existentes
    private var canSave: Bool {
        let totalItems = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
        let basicValidation = modeName.count >= 4 && modeName.count <= 18 && totalItems > 0
        let scheduleValidation = !isScheduled || (selectedWeekdays.count >= 1 && scheduleDurationIsValid)
        let noConflict = !hasScheduleConflict()
        return basicValidation && scheduleValidation && noConflict
    }
    
    private var scheduleDurationIsValid: Bool {
        guard isScheduled else { return true }
        let calendar = Calendar.current
        let startComps = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComps = calendar.dateComponents([.hour, .minute], from: endTime)
        let start = calendar.date(bySettingHour: startComps.hour ?? 0, minute: startComps.minute ?? 0, second: 0, of: Date()) ?? Date()
        let end = calendar.date(bySettingHour: endComps.hour ?? 0, minute: endComps.minute ?? 0, second: 0, of: Date()) ?? Date()
        let duration = end.timeIntervalSince(start)
        let actualDuration = duration < 0 ? duration + 86400 : duration
        return actualDuration >= 300
    }
    
    var body: some View {
        ZStack {
            Color(hex: "d9d4d3")
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                            .frame(width: 34, height: 34)
                            .background(Color(hex: "e4e0e0"))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Text("Criar modo")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        HStack {
                            TextField("ex.: Trabalho, Família", text: $modeName)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color(hex: "1C1C1E"))
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "e4e0e0"))
                        )
                        
                        if !modeName.isEmpty && modeName.count < 4 {
                            HStack {
                                Text("O nome do modo deve ter pelo menos 4 caracteres")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.red.opacity(0.7))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        } else if modeName.count > 18 {
                            HStack {
                                Text("O nome do modo deve ter no máximo 18 caracteres")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.red.opacity(0.7))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    AppIconGrid(selection: selection) {
                        showAppPicker = true
                    }

                    // Seção de Schedule (dias/horários) — opcional
                    VStack(spacing: 12) {
                        HStack {
                            Text("Agendamento")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            Spacer()
                            Toggle("", isOn: $isScheduled)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)

                        if isScheduled {
                            // Seleção de dias da semana
                            HStack(spacing: 10) {
                                ForEach(1...7, id: \.self) { day in
                                    let label = weekdayAbbrev(for: day)
                                    let isSelected = selectedWeekdays.contains(day)
                                    Text(label)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : Color(hex: "1C1C1E"))
                                        .frame(width: 34, height: 34)
                                        .background(isSelected ? Color.black : Color.white)
                                        .cornerRadius(8)
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        .onTapGesture {
                                            if isSelected {
                                                selectedWeekdays.remove(day)
                                            } else {
                                                selectedWeekdays.insert(day)
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 16)

                            // Horário inicial e final
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Início")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                    DatePicker("", selection: Binding(
                                        get: { startTime },
                                        set: { newValue in
                                            startTime = newValue
                                            // Feature 2: Atualiza automaticamente endTime para 1h após startTime
                                            if let newEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) {
                                                endTime = newEndTime
                                            }
                                        }
                                    ), displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Fim")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 16)
                            
                            // Feature 3: Mostra aviso quando schedule cruza meia-noite
                            if crossesMidnight() {
                                Text("Schedule se encerrará no dia seguinte")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(Color(hex: "9E9EA3"))
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                            }
                            
                            if !scheduleDurationIsValid {
                                Text("O agendamento deve ter pelo menos 5 minutos")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                            }
                            
                            // Feature 4: Mostra aviso de conflito com schedule existente
                            if hasScheduleConflict() {
                                Text("Conflito: já existe um schedule ativo neste horário")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.red.opacity(0.7))
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "e4e0e0"))
                    )
                    
                    // Toggle para display na tela bloqueada
                    VStack(spacing: 12) {
                        HStack {
                            Text("Mostrar na tela bloqueada")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            Spacer()
                            Toggle("", isOn: $showLiveActivity)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "e4e0e0"))
                    )
                    .onChange(of: isScheduled) { newValue in
                        // Quando o toggle é ativado, define horário de início como 10 minutos à frente
                        if newValue {
                            let now = Date()
                            if let newStartTime = Calendar.current.date(byAdding: .minute, value: 10, to: now) {
                                startTime = newStartTime
                                // Isso automaticamente atualiza endTime para 1h depois devido ao binding
                                if let newEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: newStartTime) {
                                    endTime = newEndTime
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    saveMode()
                }) {
                    Text("Salvar modo")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(canSave ? Color(hex: "1C1C1E") : Color(hex: "9E9EA3"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(canSave ? Color(hex: "d1cece") : Color.black.opacity(0.08))
                                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                        )
                }
                .disabled(!canSave)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showAppPicker) {
            AppPickerSheet(selection: $selection)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func saveMode() {
        print("📱 CreateModeView - saveMode() called")
        print("📱 Mode name: '\(modeName)'")
        print("📱 Mode name count: \(modeName.count)")
        print("📱 Apps selected count: \(selection.applicationTokens.count)")
        print("📱 Can save: \(canSave)")
        
        if canSave, let encoded = try? JSONEncoder().encode(selection) {
            let selectionKey = "mode_\(modeName)_selection"
            let existsKey = "mode_\(modeName)_exists"
            
            UserDefaults.standard.set(encoded, forKey: selectionKey)
            UserDefaults.standard.set(true, forKey: existsKey)
            UserDefaults.standard.set(showLiveActivity, forKey: "mode_\(modeName)_show_live_activity")
            UserDefaults.standard.set(Date(), forKey: "mode_\(modeName)_last_used")
            
            UserDefaults.standard.set(modeName, forKey: "active_mode_name")
            let totalCount = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
            UserDefaults.standard.set(totalCount, forKey: "active_mode_app_count")
            
            // Salva o schedule se ativado
            if isScheduled && selectedWeekdays.count >= 1 {
                // Valida que startTime < endTime ou duração >= 5 minutos
                let calendar = Calendar.current
                let startComps = calendar.dateComponents([.hour, .minute], from: startTime)
                let endComps = calendar.dateComponents([.hour, .minute], from: endTime)
                
                // Normaliza os horários para o dia de hoje para validação
                let start = calendar.date(bySettingHour: startComps.hour ?? 0, minute: startComps.minute ?? 0, second: 0, of: Date()) ?? Date()
                let end = calendar.date(bySettingHour: endComps.hour ?? 0, minute: endComps.minute ?? 0, second: 0, of: Date()) ?? Date()
                let duration = end.timeIntervalSince(start)
                let actualDuration = duration < 0 ? duration + 86400 : duration
                
                // Mínimo 5 minutos
                if actualDuration >= 300 {
                    let schedule = ScheduleModel(
                        modeName: modeName,
                        weekdays: selectedWeekdays,
                        startTime: startTime,
                        endTime: endTime,
                        isActive: true
                    )
                    ScheduleManager.shared.saveSchedule(schedule)
                    
                    // Agenda notificações normais
                    NotificationManager.shared.scheduleNotification(for: schedule)
                    
                    // Verifica se o schedule começa em menos de 10 minutos
                    let now = Date()
                    let scheduleStartToday = calendar.date(bySettingHour: startComps.hour ?? 0, minute: startComps.minute ?? 0, second: 0, of: now)
                    if let startDate = scheduleStartToday, startDate > now {
                        let minutesUntilStart = startDate.timeIntervalSince(now) / 60.0
                        // Se começa em menos de 10 minutos mas mais de 3 minutos, agenda notificação para 3 minutos
                        if minutesUntilStart < 10 && minutesUntilStart > 3 {
                            Task {
                                await NotificationManager.shared.scheduleNotificationIn3Minutes(for: schedule)
                            }
                        }
                    }
                    
                    print("✅ Schedule salvo para o modo '\(modeName)'")
                } else {
                    print("⚠️ Schedule inválido: duração mínima de 5 minutos não atendida")
                }
            }
            
            print("✅ Saved selection to: '\(selectionKey)'")
            print("✅ Set exists flag to: '\(existsKey)'")
            print("✅ Auto-selected mode: '\(modeName)'")
            
            UserDefaults.standard.synchronize()
            
            // Envia notificação para fechar o sheet e navegar para UnlockedView
            NotificationCenter.default.post(name: NSNotification.Name("ModeSaved"), object: nil)
            
            // Fecha o CreateModeView
            presentationMode.wrappedValue.dismiss()
        } else {
            print("❌ Failed to save mode")
            if !canSave {
                print("❌ Reason: canSave is false")
            }
        }
    }
    private func crossesMidnight() -> Bool {
        let calendar = Calendar.current
        let startComps = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComps = calendar.dateComponents([.hour, .minute], from: endTime)
        let startMinutes = (startComps.hour ?? 0) * 60 + (startComps.minute ?? 0)
        let endMinutes = (endComps.hour ?? 0) * 60 + (endComps.minute ?? 0)
        return endMinutes < startMinutes
    }
    
    // Feature 4: Verifica se há conflito com schedules existentes
    private func hasScheduleConflict() -> Bool {
        guard isScheduled && selectedWeekdays.count >= 1 else { return false }
        
        let allSchedules = ScheduleManager.shared.loadAllSchedules()
        let calendar = Calendar.current
        let newStartComps = calendar.dateComponents([.hour, .minute], from: startTime)
        let newEndComps = calendar.dateComponents([.hour, .minute], from: endTime)
        let newStartMinutes = (newStartComps.hour ?? 0) * 60 + (newStartComps.minute ?? 0)
        let newEndMinutes = (newEndComps.hour ?? 0) * 60 + (newEndComps.minute ?? 0)
        
        // Verifica se há schedule existente para o mesmo modo (permitindo edição)
        var existingScheduleId: String? = nil
        for schedule in allSchedules {
            if schedule.modeName == modeName {
                existingScheduleId = schedule.id
                break
            }
        }
        
        for existingSchedule in allSchedules {
            // Pula o schedule atual se for edição do mesmo modo
            if let existingId = existingScheduleId, existingSchedule.id == existingId {
                continue
            }
            
            guard existingSchedule.isActive else { continue }
            
            // Verifica se o modo do schedule ainda existe (não foi deletado)
            let modeExistsKey = "mode_\(existingSchedule.modeName)_exists"
            guard UserDefaults.standard.bool(forKey: modeExistsKey) else {
                print("   ⚠️ Schedule de modo deletado ignorado: '\(existingSchedule.modeName)'")
                continue
            }
            
            // Verifica se há sobreposição de dias
            let overlappingDays = existingSchedule.weekdays.intersection(selectedWeekdays)
            guard !overlappingDays.isEmpty else { continue }
            
            let existingStartComps = calendar.dateComponents([.hour, .minute], from: existingSchedule.startTime)
            let existingEndComps = calendar.dateComponents([.hour, .minute], from: existingSchedule.endTime)
            let existingStartMinutes = (existingStartComps.hour ?? 0) * 60 + (existingStartComps.minute ?? 0)
            let existingEndMinutes = (existingEndComps.hour ?? 0) * 60 + (existingEndComps.minute ?? 0)
            
            // Verifica conflito de horário (considera que pode cruzar meia-noite)
            func timesOverlap(start1: Int, end1: Int, start2: Int, end2: Int) -> Bool {
                // Se nenhum cruza meia-noite
                if end1 >= start1 && end2 >= start2 {
                    return start1 < end2 && start2 < end1
                }
                // Se apenas o primeiro cruza
                else if end1 < start1 && end2 >= start2 {
                    return start1 < end2 || start2 < end1
                }
                // Se apenas o segundo cruza
                else if end1 >= start1 && end2 < start2 {
                    return start1 < end2 || start2 < end1
                }
                // Se ambos cruzam
                else {
                    return true
                }
            }
            
            if timesOverlap(start1: newStartMinutes, end1: newEndMinutes, start2: existingStartMinutes, end2: existingEndMinutes) {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Helpers
private func weekdayAbbrev(for day: Int) -> String {
    // 1=Sun, 2=Mon, ... 7=Sat
    switch day {
    case 1: return "DOM"
    case 2: return "SEG"
    case 3: return "TER"
    case 4: return "QUA"
    case 5: return "QUI"
    case 6: return "SEX"
    case 7: return "SAB"
    default: return "?"
    }
}

struct AppPickerSheet: View {
    @Binding var selection: FamilyActivitySelection
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    FamilyActivityPicker(selection: $selection)
                        .frame(maxHeight: .infinity)
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Concluir")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "e4e0e0"))
                                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
        }
    }
}

#Preview {
    CreateModeView()
}
