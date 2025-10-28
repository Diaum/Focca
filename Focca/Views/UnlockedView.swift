import SwiftUI
import FamilyControls
import ManagedSettings

struct UnlockedView: View {
    @Binding var isBlocked: Bool
    @Binding var selectedTab: Int
    @State private var elapsedTime = "10h 33m"
    @State private var showModeSheet = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 60)
                
                HStack(spacing: 4) {
                    Text(elapsedTime)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    
                    Text("today")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "8A8A8E"))
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                .padding(.bottom, 70)
                
                Image("focco_rectangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 220)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                    .padding(.bottom, 60)
                
                VStack(spacing: 8) {
                    Button(action: { showModeSheet = true }) {
                        HStack(spacing: 6) {
                            Text("Mode : Allow")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "1C1C1E"))
                                .offset(y: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Text("Allowing 47 apps")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .padding(.bottom, 80)
                
                WhiteBlockButton(action: {
                    if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
                       let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                        let store = ManagedSettingsStore()
                        let apps = Set(saved.applicationTokens.compactMap { Application(token: $0) })
                        store.application.blockedApplications = apps
                        isBlocked = true
                    }
                })
                
                Spacer()
                
                TabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showModeSheet) {
            ModeSelectionSheet()
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    UnlockedView(isBlocked: .constant(false), selectedTab: .constant(0))
}

