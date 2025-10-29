import SwiftUI
import FamilyControls

struct EditModeView: View {
    let modeName: String
    @State private var editedModeName: String
    @State private var selection = FamilyActivitySelection()
    @State private var showAppPicker = false
    @State private var showDeleteConfirmation = false
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
                        saveMode()
                        presentationMode.wrappedValue.dismiss()
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
    
    private func saveMode() {
        if !editedModeName.isEmpty && editedModeName.count >= 4 && editedModeName.count <= 18, let encoded = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(encoded, forKey: "mode_\(editedModeName)_selection")
            UserDefaults.standard.set(true, forKey: "mode_\(editedModeName)_exists")
            if editedModeName != modeName {
                UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_selection")
                UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_exists")
            }
        }
    }
    
    private func deleteMode() {
        if canDelete {
            UserDefaults.standard.set(false, forKey: "mode_\(modeName)_exists")
            UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_selection")
        }
    }
}

#Preview {
    EditModeView(modeName: "default")
}
