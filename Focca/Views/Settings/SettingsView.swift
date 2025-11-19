import SwiftUI

struct SettingsView: View {
    @Binding var selectedTab: Int
    let isBlocked: Bool
    @State private var showNotificationsView = false
    @ObservedObject private var awardManager = AwardManager.shared
    @ObservedObject private var statsAchievementManager = StatsAchievementManager.shared
    
    init(selectedTab: Binding<Int>, isBlocked: Bool = false) {
        self._selectedTab = selectedTab
        self.isBlocked = isBlocked
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: isBlocked 
                    ? [Color(hex: "0A0A0A"), Color(hex: "0A0A0A")]
                    : [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(isBlocked ? Color(hex: "1C1C1C") : Color.white.opacity(0.85))
                    .frame(height: 66)
                    .overlay(
                        HStack {
                            Text("Conta")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 18)
                
                VStack(spacing: 14) {
                    SettingsSection(
                        title: "Sobre o Focca",
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
                            SettingsItem(title: "Conquistas", hasArrow: true, action: .awards)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Metas", hasArrow: true, action: .goals)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Estatísticas Avançadas", hasArrow: true, action: .advancedStats)
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
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Metas", hasToggle: true, isToggledOn: GoalsManager.shared.areGoalsEnabled, action: .goalsToggle)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 0)
            }
            
            VStack(spacing: 0) {
                Spacer()
                WhiteRoundedBottomPlain(isBlocked: isBlocked)
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -50)
            }
        }
        .preferredColorScheme(isBlocked ? .dark : .light)
        .sheet(isPresented: $showNotificationsView) {
            NotificationsView()
        }
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
                    .fill(isBlocked ? Color(hex: "1C1C1C") : Color.white)
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
    @State private var goalsEnabled = GoalsManager.shared.areGoalsEnabled
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                // Don't trigger action if it's a toggle (toggle handles its own action)
                if item.hasToggle && item.action == .goalsToggle {
                    return
                }
                
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
                case .goalsToggle:
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
                    
                    if item.hasToggle {
                        Toggle("", isOn: Binding(
                            get: { 
                                if item.action == .goalsToggle {
                                    return goalsEnabled
                                }
                                return item.isToggledOn
                            },
                            set: { newValue in
                                if item.action == .goalsToggle {
                                    goalsEnabled = newValue
                                    GoalsManager.shared.areGoalsEnabled = newValue
                                }
                            }
                        ))
                        .tint(Color.blue)
                        .labelsHidden()
                    } else if item.hasArrow {
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GoalsEnabledChanged"))) { _ in
            goalsEnabled = GoalsManager.shared.areGoalsEnabled
        }
        .onAppear {
            goalsEnabled = GoalsManager.shared.areGoalsEnabled
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
    case goalsToggle
    case advancedStats
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
    SettingsView(selectedTab: .constant(3))
}
