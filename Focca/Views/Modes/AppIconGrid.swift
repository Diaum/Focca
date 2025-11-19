import SwiftUI
import FamilyControls

struct AppIconGrid: View {
    let selection: FamilyActivitySelection
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack {
                    Text(selection.applicationTokens.count > 0 ? "Apps selecionados" : "Selecionar apps")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    Spacer()
                    if selection.applicationTokens.count > 0 {
                        Text("\(selection.applicationTokens.count)/50")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "C6C6C8"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 8),
                    spacing: 12
                ) {
                    if selection.applicationTokens.count > 0 {
                        ForEach(Array(selection.applicationTokens.prefix(16)), id: \.hashValue) { token in
                            Label(token)
                                .labelStyle(.iconOnly)
                                .font(.system(size: 42))
                                .scaleEffect(1.6)
                        }
                    } else {
                        ForEach(0..<16, id: \.self) { _ in
                            Image(systemName: "app.fill")
                                .font(.system(size: 42))
                                .foregroundColor(Color(hex: "C6C6C8"))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
    }
}

#Preview {
    let selection = FamilyActivitySelection()
    return AppIconGrid(selection: selection) {
        print("Tapped")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

