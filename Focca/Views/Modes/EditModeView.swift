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
    @Environment(\.presentationMode) var presentationMode
    
    private var canDelete: Bool {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let modeKeys = allKeys.filter { $0.hasPrefix("mode_") && $0.hasSuffix("_exists") }
        let existingModes = modeKeys.filter { UserDefaults.standard.bool(forKey: $0) }
        return existingModes.count > 1
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
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "1C1C1E"))
                            .cornerRadius(14)
                    }
                    
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
    }
    
    @discardableResult
    private func saveMode() -> Bool {
        guard !editedModeName.isEmpty && editedModeName.count >= 4 && editedModeName.count <= 18 else {
            showInvalidNameAlert = true
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

#Preview {
    EditModeView(modeName: "default")
}
