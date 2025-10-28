import SwiftUI
import FamilyControls

struct EditModeView: View {
    let modeName: String
    @State private var editedModeName: String
    @State private var selection = FamilyActivitySelection()
    @State private var showAppPicker = false
    @Environment(\.presentationMode) var presentationMode
    
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
                    
                    Button("Save") {
                        saveMode()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Text("Edit mode")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Apps Selected")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                        Spacer()
                        Text("\(selection.applicationTokens.count)/100")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
                    
                    HStack {
                        TextField("e.g. Work, Family Time", text: $editedModeName)
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
                        Text("Select Apps")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(14)
                    }
                    
                    Button(action: {
                        deleteMode()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Delete Mode")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.red)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            loadModeData()
        }
        .sheet(isPresented: $showAppPicker) {
            AppPickerSheet(selection: $selection)
        }
    }
    
    private func loadModeData() {
        if let data = UserDefaults.standard.data(forKey: "mode_\(modeName)_selection"),
           let savedSelection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = savedSelection
        }
    }
    
    private func saveMode() {
        if let encoded = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(encoded, forKey: "mode_\(editedModeName)_selection")
            UserDefaults.standard.set(true, forKey: "mode_\(editedModeName)_exists")
            if editedModeName != modeName {
                UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_selection")
                UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_exists")
            }
        }
    }
    
    private func deleteMode() {
        UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_selection")
        UserDefaults.standard.removeObject(forKey: "mode_\(modeName)_exists")
    }
}

#Preview {
    EditModeView(modeName: "default")
}

