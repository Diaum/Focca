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
    
    // Feature 1: Valida se schedule está ativo, deve ter pelo menos 1 dia selecionado
    // Feature 4: Valida se não há conflito com schedules existentes
    private var canSave: Bool {
        let basicValidation = modeName.count >= 4 && modeName.count <= 18 && CategoryExpander.totalItemCount(selection) > 0
        let scheduleValidation = !isScheduled || selectedWeekdays.count >= 1
        let noConflict = !hasScheduleConflict()
        return basicValidation && scheduleValidation && noConflict
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
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
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Text("Create mode")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                
                VStack(spacing: 16) {
                    HStack {
                        TextField("e.g. Work, Family Time", text: Binding(
                            get: { modeName },
                            set: { newValue in
                                if newValue.count <= 18 {
                                    modeName = newValue
                                }
                            }
                        ))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
                    
                    Button(action: {
                        showAppPicker = true
                    }) {
                        HStack {
                            Text("Select Apps")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "C6C6C8"))
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                        )
                    }
                    
                    AppIconGrid(selection: selection)

                    // Seção de Schedule (dias/horários) — opcional
                    VStack(spacing: 12) {
                        HStack {
                            Text("Schedule")
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
                                    Text("Start")
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
                                    Text("End")
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
                            .fill(Color.white)
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
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save mode")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(canSave ? Color(hex: "1C1C1E") : Color(hex: "9E9EA3"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(canSave ? Color(hex: "DAD7D6") : Color(hex: "EDEBEA"))
                        .cornerRadius(14)
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
        print("📱 Items selected count: \(CategoryExpander.totalItemCount(selection))")
        print("📱 Can save: \(canSave)")
        
        if canSave, let encoded = try? JSONEncoder().encode(selection) {
            let selectionKey = "mode_\(modeName)_selection"
            let existsKey = "mode_\(modeName)_exists"
            
            UserDefaults.standard.set(encoded, forKey: selectionKey)
            UserDefaults.standard.set(true, forKey: existsKey)
            UserDefaults.standard.set(Date(), forKey: "mode_\(modeName)_last_used")
            
            UserDefaults.standard.set(modeName, forKey: "active_mode_name")
            UserDefaults.standard.set(CategoryExpander.totalItemCount(selection), forKey: "active_mode_app_count")
            
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
                    print("✅ Schedule salvo para o modo '\(modeName)'")
                } else {
                    print("⚠️ Schedule inválido: duração mínima de 5 minutos não atendida")
                }
            }
            
            print("✅ Saved selection to: '\(selectionKey)'")
            print("✅ Set exists flag to: '\(existsKey)'")
            print("✅ Auto-selected mode: '\(modeName)'")
            
            UserDefaults.standard.synchronize()
            
            if let verifyData = UserDefaults.standard.data(forKey: selectionKey) {
                print("✅ Verification: Data exists for '\(selectionKey)', size: \(verifyData.count) bytes")
            } else {
                print("❌ Verification: NO data found for '\(selectionKey)'")
            }
            
            let verifyExists = UserDefaults.standard.bool(forKey: existsKey)
            print("✅ Verification: exists flag = \(verifyExists)")
        } else {
            print("❌ Failed to save mode")
            if !canSave {
                print("❌ Reason: canSave is false")
            }
        }
    }
    
    // Feature 3: Verifica se o schedule cruza meia-noite
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
    case 1: return "S"
    case 2: return "M"
    case 3: return "T"
    case 4: return "W"
    case 5: return "T"
    case 6: return "F"
    case 7: return "S"
    default: return "?"
    }
}

struct AppPickerSheet: View {
    @Binding var selection: FamilyActivitySelection
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F3F0")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    FamilyActivityPicker(selection: $selection)
                        .frame(maxHeight: .infinity)
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .cornerRadius(12)
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
