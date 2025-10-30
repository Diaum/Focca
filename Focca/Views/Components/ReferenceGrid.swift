import SwiftUI

struct ReferenceGrid: View {
    let spacing: CGFloat
    let lineWidth: CGFloat
    let color: Color
    let showCenterLines: Bool

    init(spacing: CGFloat = 20, lineWidth: CGFloat = 0.5, color: Color = .red.opacity(0.25), showCenterLines: Bool = true) {
        self.spacing = spacing
        self.lineWidth = lineWidth
        self.color = color
        self.showCenterLines = showCenterLines
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let columns = Int((width / spacing).rounded(.up))
            let rows = Int((height / spacing).rounded(.up))

            ZStack {
                // Vertical lines
                ForEach(0...columns, id: \.self) { index in
                    let x = CGFloat(index) * spacing
                    Rectangle()
                        .fill(color)
                        .frame(width: lineWidth)
                        .position(x: x, y: height / 2)
                }

                // Horizontal lines
                ForEach(0...rows, id: \.self) { index in
                    let y = CGFloat(index) * spacing
                    Rectangle()
                        .fill(color)
                        .frame(height: lineWidth)
                        .position(x: width / 2, y: y)
                }

                if showCenterLines {
                    // Center guides
                    Rectangle()
                        .fill(Color.blue.opacity(0.35))
                        .frame(width: max(lineWidth, 1))
                        .position(x: width / 2, y: height / 2)

                    Rectangle()
                        .fill(Color.blue.opacity(0.35))
                        .frame(height: max(lineWidth, 1))
                        .position(x: width / 2, y: height / 2)
                }
            }
            .compositingGroup()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ReferenceGrid(spacing: 24, color: .green.opacity(0.25))
    }
}


