import SwiftUI
import FamilyControls
import DeviceActivity

@available(iOS 17.0, *)
struct OnboardingStep3: View {
    @StateObject var model = SelectionModel()
    @State private var appInfos: [AppInfo] = []
    @State private var isLoading = true
    @State private var showMainView = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F3F0").ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("\(appInfos.count) distractions selected")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                        .padding(.top, 40)

                    if isLoading {
                        Spacer()
                        ProgressView("Loading apps...")
                            .padding()
                        Spacer()
                    } else if appInfos.isEmpty {
                        Spacer()
                        Text("No apps selected")
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(appInfos) { app in
                                    AppRow(appInfo: app)
                                    if app.id != appInfos.last?.id {
                                        Divider().padding(.leading, 62)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }

                    Spacer()

                    VStack(spacing: 16) {
                        Button("Complete setup") {
                            showMainView = true
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color(hex: "1D1D1F"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "E5E5EA"))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 20)

                        Button("Edit apps") { }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(hex: "1D1D1F"))
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 20)
                }
            }
            .navigationBarItems(leading: BackButton())
            .fullScreenCover(isPresented: $showMainView) {
                OnboardingStep4()
            }
            .task {
                if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
                   let savedSelection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                    model.selection = savedSelection
                    await loadAppInfos()
                } else {
                    isLoading = false
                }
            }
        }
    }

    private func loadAppInfos() async {
        var infos: [AppInfo] = []
        let colors: [Color] = [Color(hex: "E8B5A0"), Color(hex: "FF6B6B"), Color(hex: "4ECDC4"), Color(hex: "0A66C2"), Color(hex: "E1306C")]
        
        for (index, _) in model.selection.applicationTokens.enumerated() {
            let name = "App \(index + 1)"
            let color = colors[index % colors.count]
            infos.append(AppInfo(id: "\(index)", name: name, icon: UIImage(), color: color))
        }

        await MainActor.run {
            self.appInfos = infos
            self.isLoading = false
        }
    }
}

// MARK: - Modelos e Views auxiliares

struct AppInfo: Identifiable {
    let id: String
    let name: String
    let icon: UIImage
    let color: Color
}

struct AppRow: View {
    let appInfo: AppInfo

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(appInfo.color)
                .frame(width: 50, height: 50)
            
            Text(appInfo.name)
                .font(.system(size: 17))
                .foregroundColor(Color(hex: "1D1D1F"))
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "1D1D1F"))
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        OnboardingStep3()
    } else {
        Text("Requires iOS 17")
    }
}
