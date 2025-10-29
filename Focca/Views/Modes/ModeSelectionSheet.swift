import SwiftUI
import FamilyControls

struct ModeSelectionSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showCreateMode = false
    @State private var showEditMode = false
    @State private var editModeName: String = ""
    @State private var refreshTrigger = false
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

                Text("Select mode")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))

                VStack(spacing: 14) {
                    ForEach(modeNames, id: \.self) { modeName in
                        ModeRow(
                            title: modeName,
                            isSelected: selectedModeName == modeName,
                            onEdit: {
                                editModeName = modeName
                                showEditMode = true
                            },
                            onSelect: {
                                selectedModeName = modeName
                                saveSelectedMode(modeName)
                            }
                        )
                    }
                    
                    if modeNames.count < 3 {
                        ForEach(0..<(3 - modeNames.count), id: \.self) { _ in
                            EmptyModeRow()
                        }
                    }
                    
                    if canCreateMode {
                        CreateModeRow(showCreateMode: $showCreateMode)
                    } else {
                        MaxModesReachedRow()
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                Button(action: {}) {
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
        .sheet(isPresented: $showEditMode, onDismiss: {
            print("📥 ModeSelectionSheet - EditModeView dismissed")
            loadModeNames()
        }) {
            EditModeView(modeName: editModeName)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
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
        modeNames.count < 3
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
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(title)
                    .foregroundColor(Color(hex: "1C1C1E"))
                Spacer()
                Button(action: onEdit) {
                    Text("Edit")
                        .foregroundColor(Color(hex: "1C1C1E"))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.white : Color(hex: "EDEBEA"))
            )
        }
    }
}

private struct CreateModeRow: View {
    @Binding var showCreateMode: Bool
    
    var body: some View {
        Button(action: {
            showCreateMode = true
        }) {
            HStack {
                Text("Create new mode")
                    .foregroundColor(Color(hex: "1C1C1E"))
                Spacer()
                Image(systemName: "plus")
                    .foregroundColor(Color(hex: "1C1C1E"))
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "EDEBEA"))
            )
        }
    }
}

struct MaxModesReachedRow: View {
    var body: some View {
        Text("Maximum number of modes reached (3)")
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

struct EmptyModeRow: View {
    var body: some View {
        HStack { Spacer() }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "EDEBEA"))
            )
    }
}

#Preview { ModeSelectionSheet() }
