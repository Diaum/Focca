import SwiftUI
import FamilyControls

struct CreateModeView: View {
    @State private var modeName: String = ""
    @State private var selection = FamilyActivitySelection()
    @State private var showAppPicker = false
    @Environment(\.presentationMode) var presentationMode
    
    private var canSave: Bool {
        !modeName.isEmpty && modeName.count <= 18 && selection.applicationTokens.count > 0
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
                }
                .padding(.horizontal, 20)
                
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
        }
        .sheet(isPresented: $showAppPicker) {
            AppPickerSheet(selection: $selection)
        }
    }
    
    private func saveMode() {
        if canSave, let encoded = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(encoded, forKey: "mode_\(modeName)_selection")
            UserDefaults.standard.set(true, forKey: "mode_\(modeName)_exists")
        }
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

