import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

@available(iOS 17.0, *)
struct OnboardingStep3: View {
    @StateObject var model = SelectionModel()
    @State private var appInfos: [SelectionItem] = []
    @State private var isLoading = true
    @State private var showLoginView = false
    @State private var showStep2 = false
    @State private var showAlert = false
    @State private var isRequestingNotification = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "E3DEDB").ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("\(appInfos.count) distrações selecionadas")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "1D1D1F"))
                        .padding(.top, 40)
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    if isLoading {
                        Spacer()
                        ProgressView("Carregando apps...")
                            .padding()
                        Spacer()
                    } else if appInfos.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Text("Nenhum app selecionado")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(hex: "1D1D1F"))
                            Text("Selecione pelo menos 1 app para continuar")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "7A7A7A"))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(appInfos) { item in
                                    switch item {
                                    case .app(let appInfo):
                                        AppRow(appInfo: appInfo)
                                    case .category(let categoryInfo):
                                        CategoryRow(categoryInfo: categoryInfo)
                                    }
                                    if item.id != appInfos.last?.id {
                                        Divider().padding(.leading, 62)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }

                    Spacer()

                    VStack(spacing: 16) {
                        Button(action: {
                            let totalItems = model.selection.applicationTokens.count + model.selection.categoryTokens.count + model.selection.webDomainTokens.count
                            if totalItems > 50 {
                                showAlert = true
                            } else if totalItems > 0 && totalItems <= 50 {
                                Task {
                                    await requestNotificationPermission()
                                }
                            }
                        }) {
                            ZStack {
                                if isRequestingNotification {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Concluir configuração")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background((appInfos.isEmpty || appInfos.count > 50 || isRequestingNotification) ? Color(hex: "DAD7D6") : Color.black)
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                        }
                        .shadow(color: (appInfos.isEmpty || appInfos.count > 50 || isRequestingNotification) ? .clear : Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .disabled(appInfos.isEmpty || appInfos.count > 50 || isRequestingNotification)

                        Button(action: {
                            showStep2 = true
                        }) {
                            Text("Editar apps")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color(hex: "1D1D1F"))
                        }
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarItems(leading: BackButton(action: { showStep2 = true }))
            .preferredColorScheme(.light)
            .fullScreenCover(isPresented: $showLoginView) {
                OnboardingStep4()
            }
            .sheet(isPresented: $showStep2) {
                OnboardingStep2(didComplete: {
                    showStep2 = false
                    Task { await refreshSelectionAndApps() }
                })
            }
            .alert("Muitos itens selecionados", isPresented: $showAlert) {
                Button("Editar apps", action: {
                    showStep2 = true
                })
                Button("OK", role: .cancel) { }
            } message: {
                Text("Você só pode bloquear até 50 itens (apps, categorias ou sites). Remova alguns para continuar.")
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

    @MainActor
    private func refreshSelectionAndApps() async {
        if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
           let savedSelection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            model.selection = savedSelection
            await loadAppInfos()
        }
    }

    @MainActor
    private func loadAppInfos() async {
        isLoading = true
        let infos = await fetchAppInfo(from: model.selection)
        appInfos = infos
        isLoading = false
    }

    @available(iOS 17.0, *)
    func fetchAppInfo(from selection: FamilyActivitySelection) async -> [SelectionItem] {
        var items: [SelectionItem] = []

        // Adiciona apps
        for token in selection.applicationTokens {
            let app = Application(token: token)
            let name = app.localizedDisplayName ?? "Unknown App"
            let icon = UIImage(systemName: "app.fill")!

            items.append(.app(AppInfo(
                id: token.hashValue.description,
                name: name,
                icon: icon,
                color: .clear,
                token: token
            )))
        }
        
        // Adiciona categorias
        for token in selection.categoryTokens {
            let category = ActivityCategory(token: token)
            let name = category.localizedDisplayName ?? "Categoria"
            
            items.append(.category(CategoryInfo(
                id: token.hashValue.description,
                name: name,
                token: token
            )))
        }

        return items
    }
    
    @MainActor
    private func requestNotificationPermission() async {
        let notificationGranted = UserDefaults.standard.bool(forKey: "notification_permission_granted")
        
        if !notificationGranted {
            let notificationStatus = await NotificationManager.shared.checkAuthorizationStatus()
            
            if notificationStatus != .authorized {
                isRequestingNotification = true
                let granted = await NotificationManager.shared.requestAuthorization()
                isRequestingNotification = false
                UserDefaults.standard.set(granted, forKey: "notification_permission_granted")
                if granted {
                    showLoginView = true
                }
            } else {
                UserDefaults.standard.set(true, forKey: "notification_permission_granted")
                showLoginView = true
            }
        } else {
            showLoginView = true
        }
    }
}

enum SelectionItem: Identifiable {
    case app(AppInfo)
    case category(CategoryInfo)
    
    var id: String {
        switch self {
        case .app(let appInfo):
            return appInfo.id
        case .category(let categoryInfo):
            return categoryInfo.id
        }
    }
}

struct AppInfo {
    let id: String
    let name: String
    let icon: UIImage
    let color: Color
    let token: ApplicationToken
}

struct CategoryInfo {
    let id: String
    let name: String
    let token: ActivityCategoryToken
}

struct AppRow: View {
    let appInfo: AppInfo

    var body: some View {
        HStack(spacing: 16) {
            Label(appInfo.token)
                .labelStyle(.iconOnly)
                .frame(width: 96, height: 96)
                .scaleEffect(2.8)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Label(appInfo.token)
                    .labelStyle(.titleOnly)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(hex: "1D1D1F"))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 240, alignment: .leading)
            }

            Spacer()
        }
        .padding(.vertical, 14)
    }
}

struct CategoryRow: View {
    let categoryInfo: CategoryInfo

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "E5E5E5"))
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                Label(categoryInfo.token)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "1C1C1E"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(categoryInfo.name)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(hex: "1D1D1F"))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 240, alignment: .leading)
            }

            Spacer()
        }
        .padding(.vertical, 14)
    }
}

struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
