import SwiftUI
import UIKit

struct AdvancedStatsShareConfiguration {
    let isBlocked: Bool
    let totalTimeText: String
    let averageTimeText: String
    let streak: Int
    let weeklyGoals: Int
    let monthlyGoals: Int
}

struct AdvancedStatsShareControl: View {
    let configuration: AdvancedStatsShareConfiguration
    @State private var shareItems: [Any] = []
    @State private var shareFileURL: URL?
    @State private var isShareSheetPresented = false
    @State private var isGeneratingShareImage = false
    
    var body: some View {
        Button(action: shareStatsSnapshot) {
            HStack(spacing: 8) {
                if isGeneratingShareImage {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(configuration.isBlocked ? .white : Color(hex: "1C1C1E"))
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                }
                
                Text(isGeneratingShareImage ? "Preparing..." : "Share my stats")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(configuration.isBlocked ? .white : Color(hex: "1C1C1E"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(configuration.isBlocked ? Color(hex: "1C1C1C") : Color.white)
                    .shadow(color: Color.black.opacity(configuration.isBlocked ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
        }
        .disabled(isGeneratingShareImage)
        .sheet(isPresented: $isShareSheetPresented, onDismiss: cleanupShareFile) {
            ShareSheet(activityItems: shareItems)
                .ignoresSafeArea()
        }
    }
    
    private func shareStatsSnapshot() {
        guard !isGeneratingShareImage else { return }
        isGeneratingShareImage = true
        
        let snapshot = AdvancedStatsShareSnapshot(configuration: configuration)
        let renderer = ImageRenderer(content: snapshot)
        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            let renderedImage = renderer.uiImage
            DispatchQueue.main.async {
                if let image = renderedImage {
                    shareItems = makeShareItems(from: image)
                    isShareSheetPresented = !shareItems.isEmpty
                } else {
                    isShareSheetPresented = false
                }
                isGeneratingShareImage = false
            }
        }
    }
    
    private func makeShareItems(from image: UIImage) -> [Any] {
        if let pngData = image.pngData() {
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("advanced-stats-\(UUID().uuidString).png")
            do {
                if let existingURL = shareFileURL {
                    try? FileManager.default.removeItem(at: existingURL)
                }
                try pngData.write(to: fileURL, options: .atomic)
                shareFileURL = fileURL
                return [fileURL]
            } catch {
                shareFileURL = nil
            }
        }
        return [image]
    }
    
    private func cleanupShareFile() {
        if let url = shareFileURL {
            try? FileManager.default.removeItem(at: url)
            shareFileURL = nil
        }
        shareItems = []
    }
}

private struct AdvancedStatsShareSnapshot: View {
    let configuration: AdvancedStatsShareConfiguration
    
    private var logoName: String {
        configuration.isBlocked ? "focca-rectangle-gray" : "focca_black"
    }
    
    private var appIconImage: UIImage? {
        UIImage.appIcon ?? UIImage(named: logoName)
    }
    
    var body: some View {
        ZStack {
            Color.clear
            
            VStack(spacing: 24) {
                if let icon = appIconImage {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                }
                
                VStack(spacing: 8) {
                    Text("Total Blocked Time")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(configuration.isBlocked ? .white.opacity(0.7) : Color(hex: "8A8A8E"))
                    Text(configuration.totalTimeText)
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .foregroundColor(configuration.isBlocked ? .white : Color(hex: "1C1C1E"))
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(configuration.isBlocked ? Color(hex: "1C1C1C") : Color.white)
                        .shadow(color: Color.black.opacity(configuration.isBlocked ? 0.25 : 0.08), radius: 12, x: 0, y: 6)
                )
                
                HStack(spacing: 12) {
                    ShareStatCard(
                        title: "Streak",
                        value: "\(configuration.streak) day\(configuration.streak == 1 ? "" : "s")",
                        icon: "flame.fill",
                        isBlocked: configuration.isBlocked
                    )
                    
                    ShareStatCard(
                        title: "Avg / day",
                        value: configuration.averageTimeText,
                        icon: "clock.arrow.circlepath",
                        isBlocked: configuration.isBlocked
                    )
                }
                
                HStack(spacing: 12) {
                    ShareStatCard(
                        title: "Weekly Goals",
                        value: "\(configuration.weeklyGoals)",
                        icon: "calendar",
                        isBlocked: configuration.isBlocked
                    )
                    
                    ShareStatCard(
                        title: "Monthly Goals",
                        value: "\(configuration.monthlyGoals)",
                        icon: "calendar.circle",
                        isBlocked: configuration.isBlocked
                    )
                }
            }
            .padding(24)
        }
        .compositingGroup()
        .background(Color.clear)
    }
}

private struct ShareStatCard: View {
    let title: String
    let value: String
    let icon: String
    let isBlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
            }
            
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                .shadow(color: Color.black.opacity(isBlocked ? 0.25 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private extension UIImage {
    static var appIcon: UIImage? {
        guard
            let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let iconName = iconFiles.last,
            let iconImage = UIImage(named: iconName)
        else {
            return nil
        }
        return iconImage
    }
}

