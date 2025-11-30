import SwiftUI

struct SettingsView: View {
    @Binding var selectedTab: Int
    let isBlocked: Bool
    @State private var showNotificationsView = false
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @ObservedObject private var awardManager = AwardManager.shared
    @ObservedObject private var statsAchievementManager = StatsAchievementManager.shared
    
    private var appVersion: String {
        let year = Calendar.current.component(.year, from: Date())
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.3"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "3"
        return "\(year).\(version).\(build)"
    }
    
    init(selectedTab: Binding<Int>, isBlocked: Bool = false) {
        self._selectedTab = selectedTab
        self.isBlocked = isBlocked
    }
    
    var body: some View {
        Group {
            ZStack {
                (isBlocked
                 ? Color(hex: "242424")
                 : Color(hex: "d9d4d3"))
                .ignoresSafeArea()
                
                VStack(spacing: 14) {
                    ProfileHeaderView(
                        email: authViewModel.currentEmail ?? "usuário@focca.app",
                        isBlocked: isBlocked
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isBlocked ? Color(hex: "1C1C1C") : Color(hex: "e4e0e0"))
                            .shadow(color: isBlocked ? Color.black.opacity(0.3) : Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                    )
                    .padding(.top, 0)
                    .padding(.bottom, 14)
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Sobre o Focca", hasArrow: true),
                            SettingsItem(title: "Política de Privacidade", hasArrow: true)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Conquistas", hasArrow: true, action: .awards),
                            SettingsItem(title: "Metas", hasArrow: true, action: .goals),
                            SettingsItem(title: "Estatísticas Avançadas", hasArrow: true, action: .advancedStats)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Amigos (breve)", hasArrow: true, action: .friends)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Desbloqueio de Emergência", subtitle: "4 restantes", hasArrow: true)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await authViewModel.signOut()
                            }
                        }) {
                            Text("Deslogar")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(isBlocked ? Color(hex: "1C1C1C") : Color(hex: "d1cece"))
                                        .shadow(color: isBlocked ? Color.black.opacity(0.3) : Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("version \(appVersion)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "A0A0A0"))
                    }
                    .padding(.top, 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, -30)
                .padding(.bottom, 40)
                .zIndex(2)
                
                VStack(spacing: 0) {
                    Spacer()
                    WhiteRoundedBottomPlain(isBlocked: isBlocked)
                        .offset(y: -5)
                    TabBar(selectedTab: $selectedTab)
                        .padding(.bottom, -39)
                }
                .zIndex(1)
            }
        }
        .preferredColorScheme(isBlocked ? .dark : .light)
        .sheet(isPresented: $showNotificationsView) {
            NotificationsView()
        }
    }
    
    struct SettingsSection: View {
        let title: String?
        let items: [SettingsItem]
        @Binding var showNotificationsView: Bool
        @Binding var selectedTab: Int
        let isBlocked: Bool
        
        var body: some View {
            VStack(spacing: 10) {
                if let title = title {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
                
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        SettingsRow(item: item, showNotificationsView: $showNotificationsView, selectedTab: $selectedTab, isBlocked: isBlocked)
                        if index < items.count - 1 {
                            Divider()
                                .background(isBlocked ? Color(hex: "38383A") : Color(hex: "C6C6C8"))
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isBlocked ? Color(hex: "1C1C1C") : Color(hex: "e4e0e0"))
                        .shadow(color: isBlocked ? Color.black.opacity(0.3) : Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                )
            }
        }
    }
    
    struct SettingsRow: View {
        let item: SettingsItem
        @Binding var showNotificationsView: Bool
        @Binding var selectedTab: Int
        let isBlocked: Bool
        @ObservedObject private var awardManager = AwardManager.shared
        @ObservedObject private var statsAchievementManager = StatsAchievementManager.shared
        @State private var showAdvancedStats = false
        @State private var showGoals = false
        @State private var isExpanded = false
        
        var body: some View {
            VStack(spacing: 0) {
                Button(action: {
                    // Handle expandable items
                    if item.title == "Sobre o Focca" {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                        return
                    }
                    
                    switch item.action {
                    case .notifications:
                        showNotificationsView = true
                    case .awards:
                        selectedTab = 2
                        AwardManager.shared.markAwardsAsViewed()
                    case .advancedStats:
                        showAdvancedStats = true
                        StatsAchievementManager.shared.markAchievementsAsViewed()
                    case .goals:
                        showGoals = true
                    case .friends:
                        // TODO: Implementar tela de amigos
                        break
                    case .none:
                        break
                    }
                }) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text(item.title)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                                
                                if item.action == .awards && awardManager.hasNewAwards {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                }
                                
                                if item.action == .advancedStats && statsAchievementManager.hasNewAchievements {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            
                            if let subtitle = item.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                            }
                        }
                        
                        Spacer()
                        
                        if item.hasArrow {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8"))
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: item.subtitle != nil ? 56 : 44)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Expanded content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 2) {
                        if item.title == "Sobre o Focca" {
                            Text("Focca é um app de foco projetado para ajudá-lo a ficar longe de apps que distraem e construir melhores hábitos digitais.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .fullScreenCover(isPresented: $showAdvancedStats) {
                AdvancedStatsView(selectedTab: $selectedTab, isBlocked: isBlocked)
            }
            .fullScreenCover(isPresented: $showGoals) {
                GoalsView(selectedTab: $selectedTab, isBlocked: isBlocked)
            }
        }
    }
    
    enum SettingsAction {
        case none
        case notifications
        case awards
        case goals
        case advancedStats
        case friends
    }
    
    struct SettingsItem {
        let title: String
        var subtitle: String? = nil
        var hasArrow: Bool = false
        var hasToggle: Bool = false
        var isToggledOn: Bool = false
        var action: SettingsAction = .none
    }
    
    #Preview {
        ZStack {
            Color(hex: "d9d4d3")
                .ignoresSafeArea()
            SettingsView(selectedTab: .constant(3), isBlocked: false)
        }
    }
}
