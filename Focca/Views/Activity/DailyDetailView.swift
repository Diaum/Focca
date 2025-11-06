import SwiftUI
import FamilyControls
import ManagedSettings

struct DailyDetailView: View {
    let date: Date
    let totalTime: TimeInterval
    let isBlocked: Bool
    @Binding var selectedTab: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var appDetails: [(tokenHash: Int, time: TimeInterval)] = []
    @State private var isLoading = true
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    private var formattedTotalTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = (Int(totalTime) % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
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
            .onAppear {
                print("✅ [DailyDetailView] Gradient apareceu - date: \(date), totalTime: \(totalTime), isBlocked: \(isBlocked)")
            }
            
            VStack(spacing: 0) {
                // Header com botão de voltar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                            .frame(width: 44, height: 44)
                            .background(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                // Header
                VStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    
                    Text("Total: \(formattedTotalTime)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                } else if appDetails.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("No apps blocked")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                        Text("No blocking data available for this day")
                            .font(.system(size: 15))
                            .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(appDetails, id: \.tokenHash) { detail in
                                AppBlockingRow(tokenHash: detail.tokenHash, time: detail.time, isBlocked: isBlocked)
                                
                                if detail.tokenHash != appDetails.last?.tokenHash {
                                    Divider()
                                        .background(isBlocked ? Color(hex: "2C2C2E") : Color(hex: "C6C6C8"))
                                        .padding(.leading, 72)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isBlocked ? Color(hex: "1C1C1C") : Color.white)
                                .shadow(color: Color.black.opacity(isBlocked ? 0.3 : 0.04), radius: 3, x: 0, y: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
                
                Spacer()
                
                // Bottom arredondado e TabBar
                VStack(spacing: 0) {
                    WhiteRoundedBottomPlain(isBlocked: isBlocked)
                    TabBar(selectedTab: $selectedTab)
                        .padding(.bottom, -50)
                }
            }
        }
        .preferredColorScheme(isBlocked ? .dark : .light)
        .onAppear {
            print("✅ [DailyDetailView] onAppear chamado - date: \(date), totalTime: \(totalTime), isBlocked: \(isBlocked)")
            loadAppDetails()
        }
    }
    
    private func loadAppDetails() {
        isLoading = true
        
        // Busca os detalhes dos apps bloqueados na data
        let details = AppBlockingTracker.shared.getAppBlockingDetails(for: date)
        
        // Precisamos mapear os token hashes para ApplicationTokens
        // Para isso, precisamos buscar os tokens salvos e encontrar os que correspondem
        var appDetailsWithTokens: [(tokenHash: Int, time: TimeInterval)] = []
        
        // Busca todos os modos salvos para encontrar os tokens
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let modeKeys = allKeys.filter { $0.hasPrefix("mode_") && $0.hasSuffix("_selection") }
        
        // Usa um dicionário que mapeia hash para FamilyActivitySelection
        // e extrai o token quando necessário
        var tokenSelections: [Int: FamilyActivitySelection] = [:]
        
        for key in modeKeys {
            if let data = UserDefaults.standard.data(forKey: key),
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                for token in selection.applicationTokens {
                    // Armazena a seleção para poder extrair o token depois
                    if tokenSelections[token.hashValue] == nil {
                        tokenSelections[token.hashValue] = selection
                    }
                }
            }
        }
        
        // Também verifica a seleção padrão
        if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            for token in selection.applicationTokens {
                if tokenSelections[token.hashValue] == nil {
                    tokenSelections[token.hashValue] = selection
                }
            }
        }
        
        // Filtra apenas os apps que temos tokens e mapeia para o formato correto
        appDetailsWithTokens = details
            .filter { tokenSelections[$0.appTokenHash] != nil }
            .map { (tokenHash: $0.appTokenHash, time: $0.time) }
        
        DispatchQueue.main.async {
            self.appDetails = appDetailsWithTokens
            self.isLoading = false
        }
    }
}

struct AppBlockingRow: View {
    let tokenHash: Int
    let time: TimeInterval
    let isBlocked: Bool
    
    @State private var appToken: ApplicationToken?
    
    private var formattedTime: String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if let token = appToken {
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: 48, height: 48)
                    .scaleEffect(2.0)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isBlocked ? Color(hex: "2C2C2E") : Color(hex: "E5E5EA"))
                    .frame(width: 48, height: 48)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let token = appToken {
                    Label(token)
                        .labelStyle(.titleOnly)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isBlocked ? Color.white : Color(hex: "1C1C1E"))
                        .tint(isBlocked ? Color.white : Color(hex: "1C1C1E"))
                        .lineLimit(1)
                        .colorScheme(isBlocked ? .dark : .light)
                } else {
                    Text("Unknown App")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isBlocked ? Color.white : Color(hex: "1C1C1E"))
                }
                
                Text("Blocked for \(formattedTime)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(isBlocked ? Color(hex: "8A8A8E") : Color(hex: "8E8E93"))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .onAppear {
            loadToken()
        }
    }
    
    private func loadToken() {
        // Busca a seleção correspondente ao hash
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let modeKeys = allKeys.filter { $0.hasPrefix("mode_") && $0.hasSuffix("_selection") }
        
        for key in modeKeys {
            if let data = UserDefaults.standard.data(forKey: key),
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                if let token = selection.applicationTokens.first(where: { $0.hashValue == tokenHash }) {
                    DispatchQueue.main.async {
                        self.appToken = token
                    }
                    print("✅ [AppBlockingRow] Token encontrado para hash \(tokenHash) no modo \(key)")
                    return
                }
            }
        }
        
        // Também verifica a seleção padrão
        if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            if let token = selection.applicationTokens.first(where: { $0.hashValue == tokenHash }) {
                DispatchQueue.main.async {
                    self.appToken = token
                }
                print("✅ [AppBlockingRow] Token encontrado para hash \(tokenHash) na seleção padrão")
                return
            }
        }
        
        print("⚠️ [AppBlockingRow] Token não encontrado para hash \(tokenHash)")
    }
}

#Preview {
    DailyDetailView(date: Date(), totalTime: 6 * 3600 + 43 * 60, isBlocked: false, selectedTab: .constant(1))
}

