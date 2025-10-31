import SwiftUI

struct SettingsView: View {
    @Binding var selectedTab: Int
    @State private var showNotificationsView = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
//            .overlay(ReferenceGrid(spacing: 24, color: .red.opacity(0.15)))
            
            VStack(spacing: 0) {
                Spacer(minLength: 140)
                
                // Header card
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.85))
                    .frame(height: 66)
                    .overlay(
                        HStack {
                            Text("Account")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                
                VStack(spacing: 14) {
                    SettingsSection(
                        title: "About Focca",
                        items: [
                            SettingsItem(title: "About Focca", hasArrow: true),
                            SettingsItem(title: "Why Focca?", hasArrow: true),
                            SettingsItem(title: "Privacy Policy", hasArrow: true)
                        ],
                        showNotificationsView: $showNotificationsView
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Emergency Unblock", subtitle: "4 remaining", hasArrow: true)
                        ],
                        showNotificationsView: $showNotificationsView
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Strict mode", hasArrow: false)
                        ],
                        showNotificationsView: $showNotificationsView
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Questions", hasToggle: true, isToggledOn: true)
                        ],
                        showNotificationsView: $showNotificationsView
                    )
                    
                    SettingsSection(
                        title: nil,
                        items: [
                            SettingsItem(title: "Troubleshooting", hasArrow: true)
                        ],
                        showNotificationsView: $showNotificationsView
                    )
                    
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 24)
            }
            
            VStack(spacing: 0) {
                Spacer()
                WhiteRoundedBottomPlain()
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, -60)
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showNotificationsView) {
            NotificationsView()
        }
    }
}

struct SettingsSection: View {
    let title: String?
    let items: [SettingsItem]
    @Binding var showNotificationsView: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    SettingsRow(item: item, showNotificationsView: $showNotificationsView)
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            )
        }
    }
}

struct SettingsRow: View {
    let item: SettingsItem
    @Binding var showNotificationsView: Bool
    
    var body: some View {
        Button(action: {
            switch item.action {
            case .notifications:
                showNotificationsView = true
            case .none:
                break
            }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "8E8E93"))
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
                        .foregroundColor(Color(hex: "C6C6C8"))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: item.subtitle != nil ? 56 : 44)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SettingsAction {
    case none
    case notifications
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
