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
        Button(action: generateSnapshot) {
            HStack(spacing: 8) {
                if isGeneratingShareImage {
                    ProgressView()
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
        }
    }
    
    private func generateSnapshot() {
        guard !isGeneratingShareImage else { return }
        isGeneratingShareImage = true
        
        let snapshot = AdvancedStatsShareSnapshot(configuration: configuration)
        
        Task { @MainActor in
            let image = TransparentSnapshotRenderer.render(view: snapshot)
            
            if let image {
                shareItems = makeShareItems(from: image)
                isShareSheetPresented = !shareItems.isEmpty
            } else {
                isShareSheetPresented = false
            }
            
            isGeneratingShareImage = false
        }
    }
    
    private func makeShareItems(from image: UIImage) -> [Any] {
        guard let data = image.pngData() else { return [] }
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("advanced-stats-\(UUID().uuidString).png")
        
        do {
            if let shareFileURL {
                try? FileManager.default.removeItem(at: shareFileURL)
            }
            
            try data.write(to: url, options: .atomic)
            shareFileURL = url
            return [url]
        } catch {
            shareFileURL = nil
            return [image]
        }
    }
    
    private func cleanupShareFile() {
        if let shareFileURL {
            try? FileManager.default.removeItem(at: shareFileURL)
            self.shareFileURL = nil
        }
        shareItems = []
    }
}

struct AdvancedStatsShareSnapshot: View {
    let configuration: AdvancedStatsShareConfiguration
    
    private var iconImage: UIImage? {
        UIImage.appIcon ?? UIImage(named: "focca_black")
    }
    
    private var metrics: [ShareMetric] {
        [
            ShareMetric(label: "Total Time", value: configuration.totalTimeText),
            ShareMetric(label: "Streak", value: "\(configuration.streak) day\(configuration.streak == 1 ? "" : "s")"),
            ShareMetric(label: "Avg / day", value: configuration.averageTimeText),
            ShareMetric(label: "Weekly Goals", value: "\(configuration.weeklyGoals)"),
            ShareMetric(label: "Monthly Goals", value: "\(configuration.monthlyGoals)"),
            ShareMetric(label: "Mode", value: configuration.isBlocked ? "Blocked" : "Active")
        ]
    }
    
    var body: some View {
        ZStack {
            Color.clear
            VStack(alignment: .leading, spacing: 16) {
                if let iconImage {
                    ShareTransparencyBadge(icon: iconImage)
                }
                
                ShareBrandRow(icon: iconImage)
                
                ShareMetricsGrid(metrics: metrics)
                    .frame(maxWidth: 820, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 48)
            .padding(.vertical, 56)
        }
        .frame(width: 1080, height: 1920, alignment: .topLeading)
    }
}

private struct ShareMetric: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

private struct ShareTransparencyBadge: View {
    let icon: UIImage
    
    var body: some View {
        HStack(spacing: 8) {
            Image(uiImage: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            Text("Focca Transparent")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .textCase(.uppercase)
                .kerning(0.8)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                )
        )
    }
}

private struct ShareBrandRow: View {
    let icon: UIImage?
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            
            Text("FOCCA")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .kerning(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ShareMetricsGrid: View {
    let metrics: [ShareMetric]
    
    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 28, alignment: .leading),
            GridItem(.flexible(), spacing: 28, alignment: .leading)
        ]
    }
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
            ForEach(metrics) { metric in
                ShareMetricItem(metric: metric)
            }
        }
    }
}

private struct ShareMetricItem: View {
    let metric: ShareMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(metric.label.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.65))
                .kerning(0.8)
            Text(metric.value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum TransparentSnapshotRenderer {
    @MainActor
    static func render<V: View>(view: V) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = .clear
        
        let targetSize = CGSize(width: 1080, height: 1920)
        controller.view.bounds = CGRect(origin: .zero, size: targetSize)
        controller.view.sizeToFit()
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

extension UIImage {
    static var appIcon: UIImage? {
        guard
            let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let iconName = iconFiles.last
        else {
            return nil
        }
        
        return UIImage(named: iconName)
    }
}

