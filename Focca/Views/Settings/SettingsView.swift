import SwiftUI

struct SettingsView: View {
    @Binding var selectedTab: Int
    let isBlocked: Bool
    @State private var showNotificationsView = false
    
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
                            Text("Account")
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
                        title: "About Focca",
                        items: [
                            SettingsItem(title: "About Focca", hasArrow: true),
                            SettingsItem(title: "Why Focca?", hasArrow: true),
                            SettingsItem(title: "Privacy Policy", hasArrow: true)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Awards", hasArrow: true, action: .awards)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Emergency Unblock", subtitle: "4 remaining", hasArrow: true)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Strict mode", hasArrow: false)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Questions", hasToggle: true, isToggledOn: true)
                        ],
                        showNotificationsView: $showNotificationsView,
                        selectedTab: $selectedTab,
                        isBlocked: isBlocked
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Troubleshooting", hasArrow: true)
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
    
    var body: some View {
        Button(action: {
            switch item.action {
            case .notifications:
                showNotificationsView = true
            case .awards:
                selectedTab = 2
            case .none:
                break
            }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                    }
                }
                
                Spacer()
                
                if item.hasToggle {
                    Toggle("", isOn: .constant(item.isToggledOn))
                        .tint(Color.blue)
                        .labelsHidden()
                } else if item.hasArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "C6C6C8"))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: item.subtitle != nil ? 56 : 44)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SettingsAction {
    case none
    case notifications
    case awards
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
