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
                    
                    Spacer(minLength: 40)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            let totalCount = CategoryExpander.totalItemCount(selection)
                            let categoryCount = selection.categoryTokens.count
                            let appCount = selection.applicationTokens.count

                            if totalCount == 0 {
                                Text("Nothing selected")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            } else {
                                HStack(spacing: 8) {
                                    if categoryCount > 0 {
                                        Text("\(categoryCount) \(categoryCount == 1 ? "category" : "categories")")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "007AFF"))
                                    }
                                    if categoryCount > 0 && appCount > 0 {
                                        Text("•")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    if appCount > 0 {
                                        Text("\(appCount) \(appCount == 1 ? "app" : "apps")")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "1C1C1E"))
                                    }
                                }
                            }

                            if totalCount > 50 {
                                Text("⚠️ Maximum 50 items allowed")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            let totalCount = CategoryExpander.totalItemCount(selection)
                            if totalCount <= 50 {
                                saveSelection()
                                didComplete()
                            }
                        }) {
                            let totalCount = CategoryExpander.totalItemCount(selection)
                            Text("Next")
                                .fontWeight(.semibold)
                                .foregroundColor(totalCount > 50 ? Color(hex: "9E9EA3") : .white)
                                .padding(.horizontal, 24)
                                .frame(height: 40)
                                .background(totalCount > 50 ? Color(hex: "DAD7D6") : Color.black)
                                .cornerRadius(20)
                        }
                        .disabled(CategoryExpander.totalItemCount(selection) > 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .onAppear {
                loadSavedSelection()
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
    
    private func loadSavedSelection() {
        if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        }
    }
}

#Preview {
    OnboardingStep2(didComplete: {})
}

