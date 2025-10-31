import SwiftUI
import UserNotifications

/// View para gerenciar e visualizar configurações de notificações
struct NotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
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
                
                VStack(spacing: 4) {
                    Text("Notifications")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    
                    Text("Manage your schedule notifications")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Notification Preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preview")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "1C1C1E"))
                            
                            Text("This is how your notification will appear:")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "8E8E93"))
                                .padding(.bottom, 8)
                            
                            // Preview da notificação
                            NotificationPreview()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                        )
                        
                        // Status Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Status")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "1C1C1E"))
                                Spacer()
                                statusBadge
                            }
                            
                            Text(statusDescription)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "8E8E93"))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if authorizationStatus != .authorized {
                                Button(action: {
                                    requestAuthorization()
                                }) {
                                    Text("Enable Notifications")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.black)
                                        .cornerRadius(12)
                                }
                                .padding(.top, 8)
                            } else {
                                Button(action: {
                                    openSettings()
                                }) {
                                    Text("Open Settings")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(hex: "1C1C1E"))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                        )
                        
                        // Scheduled Notifications
                        if authorizationStatus == .authorized {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Scheduled Notifications")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "1C1C1E"))
                                    Spacer()
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                                
                                if pendingNotifications.isEmpty {
                                    Text("No scheduled notifications")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 20)
                                } else {
                                    ForEach(pendingNotifications.prefix(10), id: \.identifier) { notification in
                                        NotificationRow(notification: notification)
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            loadStatus()
        }
    }
    
    // MARK: - Status Badge
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
    }
    
    private var statusText: String {
        switch authorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Disabled"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var statusColor: Color {
        switch authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        default:
            return .gray
        }
    }
    
    private var statusDescription: String {
        switch authorizationStatus {
        case .authorized:
            return "Notifications are enabled. You'll receive reminders 10 minutes before your schedules start."
        case .denied:
            return "Notifications are disabled. Enable them in Settings to receive schedule reminders."
        case .notDetermined:
            return "Notifications permission has not been requested yet."
        default:
            return "Unknown notification status."
        }
    }
    
    // MARK: - Actions
    
    private func loadStatus() {
        Task {
            isLoading = true
            let status = await NotificationManager.shared.checkAuthorizationStatus()
            await MainActor.run {
                authorizationStatus = status
                if status == .authorized {
                    loadPendingNotifications()
                } else {
                    isLoading = false
                }
            }
        }
    }
    
    private func requestAuthorization() {
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            await MainActor.run {
                if granted {
                    authorizationStatus = .authorized
                    loadPendingNotifications()
                } else {
                    authorizationStatus = .denied
                }
                isLoading = false
            }
        }
    }
    
    private func loadPendingNotifications() {
        isLoading = true
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Filtra apenas notificações de schedules
            let scheduleNotifications = requests.filter { $0.identifier.hasPrefix("schedule_") }
            
            DispatchQueue.main.async {
                self.pendingNotifications = scheduleNotifications.sorted { $0.identifier < $1.identifier }
                self.isLoading = false
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: UNNotificationRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(extractModeName(from: notification.content.body))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                Spacer()
                Text(formatTriggerDate(from: notification))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            Text(notification.content.body)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(hex: "8E8E93"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "F7F7F8"))
        )
    }
    
    private func extractModeName(from body: String) -> String {
        // Extrai o nome do modo da mensagem: "Your 'ModeName' schedule starts in 10 minutes"
        if let startRange = body.range(of: "'"),
           let endRange = body.range(of: "'", range: startRange.upperBound..<body.endIndex) {
            return String(body[startRange.upperBound..<endRange.lowerBound])
        }
        return "Schedule"
    }
    
    private func formatTriggerDate(from request: UNNotificationRequest) -> String {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
              let weekday = trigger.dateComponents.weekday,
              let hour = trigger.dateComponents.hour,
              let minute = trigger.dateComponents.minute else {
            return ""
        }
        
        let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let weekdayName = weekdayNames[(weekday - 1) % 7]
        return "\(weekdayName) \(String(format: "%02d:%02d", hour, minute))"
    }
}

// MARK: - Notification Preview

struct NotificationPreview: View {
    @State private var selectedScheduleName = "Work Mode"
    
    var body: some View {
        VStack(spacing: 0) {
            // Simulação de notificação iOS (Lock Screen style)
            VStack(alignment: .leading, spacing: 8) {
                // App Icon + App Name
                HStack(spacing: 8) {
                    // App Icon
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1C1C1E"), Color(hex: "3A3A3C")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("F")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    // App Name
                    Text("Focca")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "1C1C1E").opacity(0.6))
                    
                    Spacer()
                    
                    // Time
                    Text("now")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "1C1C1E").opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Notification Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text("Schedule Starting Soon")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .padding(.horizontal, 16)
                    
                    // Body
                    Text("Your '\(selectedScheduleName)' schedule starts in 10 minutes")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "1C1C1E").opacity(0.8))
                        .lineLimit(3)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            
            // Preview do conteúdo da notificação
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                    .padding(.vertical, 8)
                
                Text("Notification Content:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Title:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                    }
                    Text("Schedule Starting Soon")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "F7F7F8"))
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Message:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                    }
                    Text("Your '\(selectedScheduleName)' schedule starts in 10 minutes")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "F7F7F8"))
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Timing:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Spacer()
                    }
                    Text("Sent 10 minutes before schedule starts")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "F7F7F8"))
                        )
                }
            }
            .padding(.top, 16)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "F7F7F8"))
        )
        .onAppear {
            // Carrega o primeiro schedule disponível para preview
            loadPreviewScheduleName()
        }
    }
    
    private func loadPreviewScheduleName() {
        let allSchedules = ScheduleManager.shared.loadAllSchedules()
        if let firstSchedule = allSchedules.first(where: { $0.isActive }) {
            selectedScheduleName = firstSchedule.modeName
        }
    }
}

#Preview {
    NotificationsView()
}

