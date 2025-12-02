import SwiftUI
import FamilyControls
import ManagedSettings

struct AppIconGrid: View {
    let selection: FamilyActivitySelection
    let onTap: () -> Void
    
    private var totalItems: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }
    
    private var hasSelection: Bool {
        totalItems > 0
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack {
                    Text(hasSelection ? "Apps selecionados" : "Selecionar apps")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    Spacer()
                    if hasSelection {
                        Text("\(totalItems)/50")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "1C1C1E"))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.black.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 8),
                    spacing: 12
                ) {
                    if hasSelection {
                        // Combina apps e categorias, limitando a 16 itens no total
                        let appTokens = Array(selection.applicationTokens)
                        let categoryTokens = Array(selection.categoryTokens)
                        let maxApps = min(appTokens.count, 16)
                        let remainingSlots = max(0, 16 - maxApps)
                        let maxCategories = min(categoryTokens.count, remainingSlots)
                        
                        // Mostra apps primeiro (até 16)
                        ForEach(Array(appTokens.prefix(maxApps)), id: \.hashValue) { token in
                            ZStack {
                                Color.clear
                                Label(token)
                                    .labelStyle(.iconOnly)
                                    .font(.system(size: 42))
                                    .scaleEffect(1.6)
                            }
                        }
                        
                        // Mostra categorias depois (preenchendo os slots restantes até 16 total)
                        ForEach(Array(categoryTokens.prefix(maxCategories)), id: \.hashValue) { token in
                            ZStack {
                                Color.clear
                                Label(token)
                                    .labelStyle(.iconOnly)
                                    .font(.system(size: 42))
                                    .scaleEffect(1.6)
                            }
                        }
                        
                        // Preenche espaços vazios se houver menos de 16 itens
                        let totalDisplayed = maxApps + maxCategories
                        let emptySlots = max(0, 16 - totalDisplayed)
                        ForEach(0..<emptySlots, id: \.self) { _ in
                            Color.clear
                                .frame(width: 42, height: 42)
                        }
                    } else {
                        ForEach(0..<16, id: \.self) { _ in
                            Image(systemName: "app.fill")
                                .font(.system(size: 42))
                                .foregroundColor(Color.black.opacity(0.1))
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
                .fill(Color(hex: "e4e0e0"))
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

