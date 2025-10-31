import SwiftUI
import FamilyControls

struct AppIconGrid: View {
    let selection: FamilyActivitySelection
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Apps Selected")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "1C1C1E"))
                Spacer()
                Text("\(selection.applicationTokens.count)/50")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "1C1C1E"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 8),
                spacing: 0
            ) {
                if selection.applicationTokens.count > 0 {
                    ForEach(Array(selection.applicationTokens.prefix(12)), id: \.hashValue) { token in
                        Label(token)
                            .labelStyle(.iconOnly)
                            .font(.system(size: 42))
                    }
                } else {
                    ForEach(0..<12, id: \.self) { _ in
                        Image(systemName: "app.fill")
                            .font(.system(size: 42))
                            .foregroundColor(Color(hex: "C6C6C8"))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
    }
}

#Preview {
    let selection = FamilyActivitySelection()
    return AppIconGrid(selection: selection)
        .padding()
        .background(Color.gray.opacity(0.1))
}

