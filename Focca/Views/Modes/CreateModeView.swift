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
    
    private var canSave: Bool {
        modeName.count >= 4 && modeName.count <= 18 && selection.applicationTokens.count > 0
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
                                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
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
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
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
        print("📱 Apps selected count: \(selection.applicationTokens.count)")
        print("📱 Can save: \(canSave)")
        
        if canSave, let encoded = try? JSONEncoder().encode(selection) {
            let selectionKey = "mode_\(modeName)_selection"
            let existsKey = "mode_\(modeName)_exists"
            
            UserDefaults.standard.set(encoded, forKey: selectionKey)
            UserDefaults.standard.set(true, forKey: existsKey)
            UserDefaults.standard.set(Date(), forKey: "mode_\(modeName)_last_used")
            
            UserDefaults.standard.set(modeName, forKey: "active_mode_name")
            UserDefaults.standard.set(selection.applicationTokens.count, forKey: "active_mode_app_count")
            
            // Salva (opcional) o agendamento simples em UserDefaults para uso futuro
            if isScheduled {
                let comp = Calendar.current
                let start = comp.dateComponents([.hour, .minute], from: startTime)
                let end = comp.dateComponents([.hour, .minute], from: endTime)
                let schedule: [String: Any] = [
                    "weekdays": Array(selectedWeekdays).sorted(),
                    "startHour": start.hour ?? 0,
                    "startMinute": start.minute ?? 0,
                    "endHour": end.hour ?? 0,
                    "endMinute": end.minute ?? 0
                ]
                UserDefaults.standard.set(schedule, forKey: "mode_\(modeName)_schedule")
            } else {
                UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_schedule")
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
