import SwiftUI
import FamilyControls

extension String: Identifiable {
    public var id: String { self }
}

struct ModeSelectionSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var editModeName: String?
    @State private var modeNames: [String] = []
    @State private var selectedModeName: String = ""
    
    var body: some View {
        ZStack {
            Color(hex: "d9d4d3").ignoresSafeArea()
            
            VStack(spacing: 0) {
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
                                    .fill(Color(hex: "e4e0e0"))
                                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
                            )
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)

                Text("Selecionar modo")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                    .padding(.bottom, 70)

                VStack(spacing: 14) {
                    ForEach(modeNames, id: \.self) { modeName in
                        ModeRow(
                            title: modeName,
                            isSelected: selectedModeName == modeName,
                            onEdit: {
                                presentationMode.wrappedValue.dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    NotificationCenter.default.post(name: NSNotification.Name("OpenEditMode"), object: modeName)
                                }
                            },
                            onSelect: {
                                selectedModeName = modeName
                                saveSelectedMode(modeName)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                if canCreateMode {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: NSNotification.Name("OpenCreateMode"), object: nil)
                        }
                    }) {
                        Text("Criar novo modo")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "d1cece"))
                                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                } else {
                    Text("Limite máximo de modos atingido (6)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "FF6B6B"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "FFEBEE"))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
        }
        .sheet(item: $editModeName) { modeName in
            EditModeView(modeName: modeName)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
                .onDisappear {
                    loadModeNames()
                    loadSelectedMode()
                    // Notifica que os dados foram atualizados
                    NotificationCenter.default.post(name: NSNotification.Name("ModeDataUpdated"), object: nil)
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ModeSaved"))) { _ in
            // Quando um modo é salvo, fecha o ModeSelectionSheet também
            print("📥 [ModeSelectionSheet] Modo salvo, fechando sheet")
            presentationMode.wrappedValue.dismiss()
        }
        .onAppear {
            loadModeNames()
            loadSelectedMode()
        }
    }
    
    private func loadModeNames() {
        print("🔄 ModeSelectionSheet - Loading mode names")
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let modeKeys = allKeys.filter { $0.hasPrefix("mode_") && $0.hasSuffix("_exists") }
        
        var names: [String] = []
        for key in modeKeys {
            if UserDefaults.standard.bool(forKey: key) {
                let name = key.replacingOccurrences(of: "mode_", with: "").replacingOccurrences(of: "_exists", with: "")
                names.append(name)
                print("   - Found mode: '\(name)'")
            }
        }
        
        // Obtém o modo selecionado
        let selectedMode = UserDefaults.standard.string(forKey: "active_mode_name") ?? ""
        
        var modes: [(name: String, lastUsed: Date)] = []
        for name in names {
            let lastUsed = UserDefaults.standard.object(forKey: "mode_\(name)_last_used") as? Date ?? Date.distantPast
            modes.append((name: name, lastUsed: lastUsed))
            print("   - Mode '\(name)' last used: \(lastUsed)")
        }
        
        // Ordena: primeiro o modo selecionado (se existir), depois por uso (mais recente primeiro)
        modes.sort { mode1, mode2 in
            // Se um deles é o modo selecionado, ele vem primeiro
            if mode1.name == selectedMode && mode2.name != selectedMode {
                return true
            }
            if mode2.name == selectedMode && mode1.name != selectedMode {
                return false
            }
            // Se ambos são ou não são selecionados, ordena por uso
            return mode1.lastUsed > mode2.lastUsed
        }
        
        modeNames = modes.map { $0.name }
        print("🔄 ModeSelectionSheet - Loaded \(modeNames.count) modes (selected: '\(selectedMode)')")
    }
    
    private var canCreateMode: Bool {
        modeNames.count < 6
    }
    
    private func loadSelectedMode() {
        selectedModeName = UserDefaults.standard.string(forKey: "active_mode_name") ?? ""
        print("📱 ModeSelectionSheet - Loaded selected mode: '\(selectedModeName)'")
    }
    
    private func saveSelectedMode(_ modeName: String) {
        UserDefaults.standard.set(modeName, forKey: "active_mode_name")
        UserDefaults.standard.set(Date(), forKey: "mode_\(modeName)_last_used")
        
        if let data = UserDefaults.standard.data(forKey: "mode_\(modeName)_selection"),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            let totalCount = saved.applicationTokens.count + saved.categoryTokens.count + saved.webDomainTokens.count
            UserDefaults.standard.set(totalCount, forKey: "active_mode_app_count")
            
            let encoded = try? JSONEncoder().encode(saved)
            UserDefaults.standard.set(encoded, forKey: "familyActivitySelection")
        }
        
        print("✅ Selected mode: '\(modeName)'")
        presentationMode.wrappedValue.dismiss()
    }
}

struct ModeRow: View {
    let title: String
    let isSelected: Bool
    let onEdit: () -> Void
    let onSelect: () -> Void
    
    private var hasSchedule: Bool {
        let allSchedules = ScheduleManager.shared.loadAllSchedules()
        return allSchedules.contains(where: { $0.modeName == title && $0.isActive && UserDefaults.standard.bool(forKey: "mode_\($0.modeName)_exists") })
    }

    var body: some View {
                HStack(spacing: 0) {
                    Button(action: onSelect) {
                        HStack(spacing: 8) {
                            Text(title)
                                .foregroundColor(Color(hex: "1C1C1E"))
                            if hasSchedule {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(hex: "C6C6C8"))
                            }
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .frame(height: 84)
                    }

                    Button(action: onEdit) {
                        Text("Editar")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(hex: "1C1C1E"))
                            .padding(.horizontal, 16)
                            .frame(height: 74)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isSelected ? Color(hex: "e4e0e0") : Color(hex: "d0cbcb"))
                )
    }
}

#Preview {
    let defaults = UserDefaults.standard

    for key in defaults.dictionaryRepresentation().keys {
        if key.hasPrefix("mode_") {
            defaults.removeObject(forKey: key)
        }
    }

    defaults.set(true, forKey: "mode_Deep Focus_exists")
    defaults.set(5, forKey: "mode_Deep Focus_app_count")
    defaults.set(Date().addingTimeInterval(-86400), forKey: "mode_Deep Focus_last_used")

    defaults.set(true, forKey: "mode_Work Mode_exists")
    defaults.set(8, forKey: "mode_Work Mode_app_count")
    defaults.set(Date(), forKey: "mode_Work Mode_last_used")
    defaults.set("Work Mode", forKey: "active_mode_name")
    defaults.set(8, forKey: "active_mode_app_count")

    defaults.set(true, forKey: "mode_Family Time_exists")
    defaults.set(3, forKey: "mode_Family Time_app_count")
    defaults.set(Date().addingTimeInterval(-172800), forKey: "mode_Family Time_last_used")

    return ModeSelectionSheet()
}
