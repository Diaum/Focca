import SwiftUI
import FamilyControls

struct EditModeView: View {
    let modeName: String
    @State private var editedModeName: String
    @State private var selection = FamilyActivitySelection()
    @State private var showAppPicker = false
    @State private var showDeleteConfirmation = false
    @State private var showDuplicateNameAlert = false
    @State private var showInvalidNameAlert = false
    @State private var isScheduled: Bool = false
    @State private var selectedWeekdays: Set<Int> = []
    @State private var startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @Environment(\.presentationMode) var presentationMode
    
    private var canDelete: Bool {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let modeKeys = allKeys.filter { $0.hasPrefix("mode_") && $0.hasSuffix("_exists") }
        let existingModes = modeKeys.filter { UserDefaults.standard.bool(forKey: $0) }
        return existingModes.count > 1
    }
    
    private var canSave: Bool {
        // Validação básica do nome do modo
        guard !editedModeName.isEmpty && editedModeName.count >= 4 && editedModeName.count <= 18 else {
            return false
        }
        
        // Validação básica da seleção de apps
        guard CategoryExpander.totalItemCount(selection) > 0 else {
            return false
        }
        
        // Se o schedule estiver ativado, valida os dados do schedule
        if isScheduled {
            // Deve ter pelo menos 1 dia selecionado
            guard selectedWeekdays.count >= 1 else {
                return false
            }
            
            // Deve ter horário válido (mínimo 5 minutos)
            let calendar = Calendar.current
            let startComps = calendar.dateComponents([.hour, .minute], from: startTime)
            let endComps = calendar.dateComponents([.hour, .minute], from: endTime)
            
            let start = calendar.date(bySettingHour: startComps.hour ?? 0, minute: startComps.minute ?? 0, second: 0, of: Date()) ?? Date()
            let end = calendar.date(bySettingHour: endComps.hour ?? 0, minute: endComps.minute ?? 0, second: 0, of: Date()) ?? Date()
            let duration = end.timeIntervalSince(start)
            let actualDuration = duration < 0 ? duration + 86400 : duration
            
            guard actualDuration >= 300 else { // Mínimo 5 minutos
                return false
            }
            
            // Não deve haver conflito de schedule
            if hasScheduleConflict() {
                return false
            }
        }
        
        return true
    }
    
    init(modeName: String) {
        self.modeName = modeName
        self._editedModeName = State(initialValue: modeName)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                            )
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                VStack(spacing: 4) {
                    Text("Edit mode")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "8E8E93"))
                    
                    Text(modeName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "1C1C1E"))
                }
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Mode name")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                        TextField("e.g. Work, Family Time", text: Binding(
                            get: { editedModeName },
                            set: { newValue in
                                if newValue.count <= 18 {
                                    editedModeName = newValue
                                }
                            }
                        ))
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .multilineTextAlignment(.trailing)
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
                            
                            // Mostra aviso quando schedule cruza meia-noite
                            if crossesMidnight() {
                                Text("Schedule se encerrará no dia seguinte")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(Color(hex: "9E9EA3"))
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                            }
                            
                            // Mostra aviso de conflito com schedule existente
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
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        if saveMode() {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Text("Save")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(canSave ? .white : Color(hex: "9E9EA3"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(canSave ? Color(hex: "1C1C1E") : Color(hex: "EDEBEA"))
                            .cornerRadius(14)
                    }
                    .disabled(!canSave)
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Delete Mode")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(canDelete ? .white : Color(hex: "9E9EA3"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(canDelete ? Color.red : Color(hex: "EDEBEA"))
                            .cornerRadius(14)
                    }
                    .disabled(!canDelete)
                    .alert("Delete Mode", isPresented: $showDeleteConfirmation) {
                        Button("Cancel", role: .cancel) {}
                        Button("Delete", role: .destructive) {
                            deleteMode()
                            presentationMode.wrappedValue.dismiss()
                        }
                    } message: {
                        Text("Are you sure you want to delete this mode? This action cannot be undone.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showAppPicker) {
            AppPickerSheet(selection: $selection)
        }
        .alert("Duplicate Name", isPresented: $showDuplicateNameAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A mode with the name '\(editedModeName)' already exists. Please choose a different name.")
        }
        .alert("Invalid Name", isPresented: $showInvalidNameAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Mode name must be between 4 and 18 characters.")
        }
        .onAppear {
            loadModeData()
        }
    }
    
    private func loadModeData() {
        if let data = UserDefaults.standard.data(forKey: "mode_\(modeName)_selection"),
           let savedSelection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = savedSelection
        }
        
        // Carrega schedule existente se houver
        let allSchedules = ScheduleManager.shared.loadAllSchedules()
        if let existingSchedule = allSchedules.first(where: { $0.modeName == modeName && $0.isActive }) {
            isScheduled = true
            selectedWeekdays = existingSchedule.weekdays
            startTime = existingSchedule.startTime
            endTime = existingSchedule.endTime
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
            if schedule.modeName == editedModeName {
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
            
            let modeExistsKey = "mode_\(existingSchedule.modeName)_exists"
            guard UserDefaults.standard.bool(forKey: modeExistsKey) else {
                continue
            }
            
            let overlappingDays = existingSchedule.weekdays.intersection(selectedWeekdays)
            guard !overlappingDays.isEmpty else { continue }
            
            let existingStartComps = calendar.dateComponents([.hour, .minute], from: existingSchedule.startTime)
            let existingEndComps = calendar.dateComponents([.hour, .minute], from: existingSchedule.endTime)
            let existingStartMinutes = (existingStartComps.hour ?? 0) * 60 + (existingStartComps.minute ?? 0)
            let existingEndMinutes = (existingEndComps.hour ?? 0) * 60 + (existingEndComps.minute ?? 0)
            
            func timesOverlap(start1: Int, end1: Int, start2: Int, end2: Int) -> Bool {
                if end1 >= start1 && end2 >= start2 {
                    return start1 < end2 && start2 < end1
                } else if end1 < start1 && end2 >= start2 {
                    return start1 < end2 || start2 < end1
                } else if end1 >= start1 && end2 < start2 {
                    return start1 < end2 || start2 < end1
                } else {
                    return true
                }
            }
            
            if timesOverlap(start1: newStartMinutes, end1: newEndMinutes, start2: existingStartMinutes, end2: existingEndMinutes) {
                return true
            }
        }
        
        return false
    }
    
    @discardableResult
    private func saveMode() -> Bool {
        guard canSave else {
            if !editedModeName.isEmpty && editedModeName.count >= 4 && editedModeName.count <= 18 {
                showInvalidNameAlert = true
            }
            return false
        }

        guard let encoded = try? JSONEncoder().encode(selection) else {
            return false
        }

        if editedModeName != modeName {
            let newModeExists = UserDefaults.standard.bool(forKey: "mode_\(editedModeName)_exists")
            if newModeExists {
                showDuplicateNameAlert = true
                return false
            }

            UserDefaults.standard.set(encoded, forKey: "mode_\(editedModeName)_selection")
            UserDefaults.standard.set(true, forKey: "mode_\(editedModeName)_exists")

            if let lastUsed = UserDefaults.standard.object(forKey: "mode_\(modeName)_last_used") as? Date {
                UserDefaults.standard.set(lastUsed, forKey: "mode_\(editedModeName)_last_used")
            }

            if let schedule = UserDefaults.standard.data(forKey: "mode_\(modeName)_schedule") {
                UserDefaults.standard.set(schedule, forKey: "mode_\(editedModeName)_schedule")
            }

            let activeModeModeName = UserDefaults.standard.string(forKey: "active_mode_name")
            if activeModeModeName == modeName {
                UserDefaults.standard.set(editedModeName, forKey: "active_mode_name")
            }

            UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_selection")
            UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_exists")
            UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_last_used")
            UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_schedule")

        } else {
            UserDefaults.standard.set(encoded, forKey: "mode_\(editedModeName)_selection")
            UserDefaults.standard.set(true, forKey: "mode_\(editedModeName)_exists")
        }
        
        // Salva ou remove o schedule
        let finalModeName = editedModeName != modeName ? editedModeName : modeName
        
        // Remove schedule antigo do modo original se o nome mudou
        if editedModeName != modeName {
            ScheduleManager.shared.removeSchedulesForMode(modeName: modeName)
        }
        
        // Remove schedule existente do modo (vai ser recriado se necessário)
        ScheduleManager.shared.removeSchedulesForMode(modeName: finalModeName)
        
        // Salva novo schedule se ativado
        if isScheduled && selectedWeekdays.count >= 1 {
            let calendar = Calendar.current
            let startComps = calendar.dateComponents([.hour, .minute], from: startTime)
            let endComps = calendar.dateComponents([.hour, .minute], from: endTime)
            
            let start = calendar.date(bySettingHour: startComps.hour ?? 0, minute: startComps.minute ?? 0, second: 0, of: Date()) ?? Date()
            let end = calendar.date(bySettingHour: endComps.hour ?? 0, minute: endComps.minute ?? 0, second: 0, of: Date()) ?? Date()
            let duration = end.timeIntervalSince(start)
            let actualDuration = duration < 0 ? duration + 86400 : duration
            
            if actualDuration >= 300 {
                let schedule = ScheduleModel(
                    modeName: finalModeName,
                    weekdays: selectedWeekdays,
                    startTime: startTime,
                    endTime: endTime,
                    isActive: true
                )
                ScheduleManager.shared.saveSchedule(schedule)
            }
        }

        return true
    }
    
    private func deleteMode() {
        if canDelete {
            // Remove os schedules associados ao modo antes de deletar
            ScheduleManager.shared.removeSchedulesForMode(modeName: modeName)
            
            // Remove outros dados relacionados ao modo
            UserDefaults.standard.set(false, forKey: "mode_\(modeName)_exists")
            UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_selection")
            UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_last_used")
            UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_schedule")
            
            // Se este modo estava ativo, limpa as referências
            if UserDefaults.standard.string(forKey: "active_mode_name") == modeName {
                UserDefaults.standard.removeObject(forKey: "active_mode_name")
                UserDefaults.standard.removeObject(forKey: "active_mode_app_count")
            }
            
            print("🗑️ [EditModeView] Modo '\(modeName)' deletado e schedules removidos")
        }
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

#Preview {
    EditModeView(modeName: "default")
}
