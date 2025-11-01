import SwiftUI
import FamilyControls

extension String: Identifiable {
    public var id: String { self }
}

struct ModeSelectionSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showCreateMode = false
    @State private var editModeName: String?
    @State private var modeNames: [String] = []
    @State private var selectedModeName: String = ""
    @State private var shouldDismissParent = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
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
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                            )
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)

                Text("Select mode")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                    .padding(.bottom, 70)

                VStack(spacing: 14) {
                    ForEach(modeNames, id: \.self) { modeName in
                        ModeRow(
                            title: modeName,
                            isSelected: selectedModeName == modeName,
                            onEdit: {
                                editModeName = modeName
                            },
                            onSelect: {
                                selectedModeName = modeName
                                saveSelectedMode(modeName)
                            }
                        )
                    }
                    
                    if canCreateMode {
                        
                        CreateModeRow(
                            showCreateMode: $showCreateMode,
                            isDisabled: !canCreateMode
                        )
                    } else {
                        MaxModesReachedRow()
                    }
                    
                }
                .padding(.horizontal, 20)

                Spacer()

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "DAD7D6"))
                        .cornerRadius(20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showCreateMode, onDismiss: {
            print("📥 ModeSelectionSheet - CreateModeView dismissed")
            loadModeNames()
            if shouldDismissParent {
                presentationMode.wrappedValue.dismiss()
            }
            shouldDismissParent = false
        }) {
            CreateModeView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .sheet(item: $editModeName) { modeName in
            EditModeView(modeName: modeName)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
                .onDisappear {
                    loadModeNames()
                }
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
        
        var modes: [(name: String, lastUsed: Date)] = []
        for name in names {
            let lastUsed = UserDefaults.standard.object(forKey: "mode_\(name)_last_used") as? Date ?? Date.distantPast
            modes.append((name: name, lastUsed: lastUsed))
            print("   - Mode '\(name)' last used: \(lastUsed)")
        }
        modes.sort { $0.lastUsed > $1.lastUsed }
        modeNames = modes.map { $0.name }
        print("🔄 ModeSelectionSheet - Loaded \(modeNames.count) modes")
    }
    
    private var canCreateMode: Bool {
        modeNames.count < 4
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
            UserDefaults.standard.set(saved.applicationTokens.count, forKey: "active_mode_app_count")
            
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
                Text("Edit")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "1C1C1E"))
                    .padding(.horizontal, 16)
                    .frame(height: 74)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.white : Color(hex: "EDEBEA"))
        )
    }
}

private struct CreateModeRow: View {
    @Binding var showCreateMode: Bool
    let isDisabled: Bool

    var body: some View {
        Button(action: {
            if !isDisabled {
                showCreateMode = true
            }
        }) {
            HStack {
                Text("Create new mode")
                    .foregroundColor(isDisabled ? Color(hex: "9E9EA3") : Color(hex: "1C1C1E"))
                Spacer()
                Image(systemName: "plus")
                    .foregroundColor(isDisabled ? Color(hex: "9E9EA3") : Color(hex: "1C1C1E"))
            }
            .padding(.horizontal, 16)
            .frame(height: 84)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "EDEBEA"))
            )
        }
        .disabled(isDisabled)
    }
}

struct MaxModesReachedRow: View {
    var body: some View {
        Text("Maximum number of modes reached (4)")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color(hex: "FF6B6B"))
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "FFEBEE"))
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
