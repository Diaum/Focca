import SwiftUI
import UIKit

struct AdvancedStatsShareConfiguration {
    let isBlocked: Bool
    let totalTimeText: String
    let averageTimeText: String
    let streak: Int
    let weeklyAverage: String
    let monthlyAverage: String
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
                Text(isGeneratingShareImage ? "Preparando..." : "Compartilhar minhas estatísticas")
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
            ShareMetric(label: "Tempo Total", value: configuration.totalTimeText),
            ShareMetric(label: "Sequência", value: "\(configuration.streak) dia\(configuration.streak == 1 ? "" : "s")"),
            ShareMetric(label: "Média / dia", value: configuration.averageTimeText),
            ShareMetric(label: "Média / semana", value: configuration.weeklyAverage),
            ShareMetric(label: "Média / mês", value: configuration.monthlyAverage)
        ]
    }
    
    var body: some View {
        ZStack {
            Color.clear
            VStack(alignment: .leading, spacing: 40) {
                ShareBrandRow(icon: iconImage)
                
                ShareMetricsGrid(metrics: metrics)
                    .frame(maxWidth: 900, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 96)
            .padding(.vertical, 120)
        }
        .frame(width: 1080, height: 1920, alignment: .topLeading)
    }
}

private struct ShareMetric: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

private struct ShareBrandRow: View {
    let icon: UIImage?
    
    var body: some View {
        HStack(spacing: 18) {
            if let icon {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            
            Text("FOCCA")
                .font(.system(size: 58, weight: .black, design: .rounded))
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
            GridItem(.flexible(), spacing: 32, alignment: .leading),
            GridItem(.flexible(), spacing: 32, alignment: .leading)
        ]
    }
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 28) {
            ForEach(metrics) { metric in
                ShareMetricItem(metric: metric)
            }
        }
    }
}

private struct ShareMetricItem: View {
    let metric: ShareMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(metric.label.uppercased())
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.65))
                .kerning(0.8)
            Text(metric.value)
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
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

