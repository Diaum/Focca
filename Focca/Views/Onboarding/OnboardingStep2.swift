import SwiftUI
import FamilyControls
import ManagedSettings

struct OnboardingStep2: View {
    @State private var selection = FamilyActivitySelection()
    @Environment(\.presentationMode) var presentationMode
    let didComplete: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F3F0")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    FamilyActivityPicker(selection: $selection)
                        .frame(maxHeight: .infinity)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(selection.applicationTokens.count + selection.categoryTokens.count)/50 items selected")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            if selection.categoryTokens.count > 0 && selection.applicationTokens.count == 0 {
                                Text("⚠️ Tap category \"All\" to select all apps")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            saveSelection()
                            didComplete()
                        }) {
                            Text("Next")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .frame(height: 40)
                                .background(Color.black)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .onAppear {
                Task {
                    try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                }
            }
        }
    }
    
    private func saveSelection() {
        saveAppsToUserDefaults()
    }
    
    private func saveAppsToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(encoded, forKey: "familyActivitySelection")
        }
    }
}

#Preview {
    OnboardingStep2(didComplete: {})
}

