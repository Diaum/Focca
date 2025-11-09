//
//  FoccaWidgetLive.swift
//  FoccaWidgetLive
//
//  Created by Fiasco on 30/10/25.
//

import WidgetKit
import SwiftUI
import FamilyControls
import ManagedSettings
import ActivityKit

struct Provider: AppIntentTimelineProvider {
    private let standardDefaults = UserDefaults.standard
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            isBlocked: false,
            startDate: nil as Date?,
            appTokenHashes: []
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let (isBlocked, startDate, appTokenHashes) = loadBlockingData()
        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            isBlocked: isBlocked,
            startDate: startDate,
            appTokenHashes: appTokenHashes
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let (isBlocked, startDate, appTokenHashes) = loadBlockingData()
        
        let currentDate = Date()
        var entries: [SimpleEntry] = []
        
        // Atualiza a cada minuto quando bloqueado
        if isBlocked, let startDate = startDate {
            for minuteOffset in 0..<60 {
                let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
                let entry = SimpleEntry(
                    date: entryDate,
                    configuration: configuration,
                    isBlocked: true,
                    startDate: startDate,
                    appTokenHashes: appTokenHashes
                )
                entries.append(entry)
            }
            return Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!))
        } else {
            // Quando não bloqueado, atualiza a cada hora
            for hourOffset in 0..<5 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                let entry = SimpleEntry(
                    date: entryDate,
                    configuration: configuration,
                    isBlocked: false,
                    startDate: nil as Date?,
                    appTokenHashes: []
                )
                entries.append(entry)
            }
            return Timeline(entries: entries, policy: .atEnd)
        }
    }
    
    private func loadBlockingData() -> (isBlocked: Bool, startDate: Date?, appTokenHashes: [Int]) {
        // Verifica se está bloqueado usando o standardDefaults
        let isBlocked = standardDefaults.object(forKey: "blocked_start_date") != nil
        let startDate = standardDefaults.object(forKey: "blocked_start_date") as? Date
        
        var appTokenHashes: [Int] = []
        if isBlocked {
            // Tenta carregar do standardDefaults primeiro (modos salvos no app principal)
            if let modeName = standardDefaults.string(forKey: "active_mode_name"),
               let data = standardDefaults.data(forKey: "mode_\(modeName)_selection"),
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                appTokenHashes = selection.applicationTokens.map { $0.hashValue }
            } else if let data = standardDefaults.data(forKey: "familyActivitySelection"),
                      let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                appTokenHashes = selection.applicationTokens.map { $0.hashValue }
            }
            
        }
        
        return (isBlocked, startDate, appTokenHashes)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let isBlocked: Bool
    let startDate: Date?
    let appTokenHashes: [Int]
}

struct FoccaWidgetLiveEntryView : View {
    var entry: Provider.Entry
    
    private let standardDefaults = UserDefaults.standard
    
    private var appTokens: [ApplicationToken] {
        guard entry.isBlocked, !entry.appTokenHashes.isEmpty else { return [] }
        
        // Carrega os tokens a partir dos hashes
        var tokens: [ApplicationToken] = []
        
        // Primeiro tenta carregar do modo ativo no standardDefaults
        if let modeName = standardDefaults.string(forKey: "active_mode_name"),
           let data = standardDefaults.data(forKey: "mode_\(modeName)_selection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            for token in selection.applicationTokens {
                if entry.appTokenHashes.contains(token.hashValue) {
                    tokens.append(token)
                }
            }
        }
        
        // Se não encontrou tokens suficientes, busca em todos os modos no standardDefaults
        if tokens.count < entry.appTokenHashes.count {
            let allKeys = standardDefaults.dictionaryRepresentation().keys
            let modeKeys = allKeys.filter { $0.hasPrefix("mode_") && $0.hasSuffix("_selection") }
            
            for key in modeKeys {
                if let data = standardDefaults.data(forKey: key),
                   let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                    for token in selection.applicationTokens {
                        if entry.appTokenHashes.contains(token.hashValue) && !tokens.contains(where: { $0.hashValue == token.hashValue }) {
                            tokens.append(token)
                        }
                    }
                }
            }
        }
        
        // Também verifica a seleção padrão no standardDefaults
        if tokens.count < entry.appTokenHashes.count,
           let data = standardDefaults.data(forKey: "familyActivitySelection"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            for token in selection.applicationTokens {
                if entry.appTokenHashes.contains(token.hashValue) && !tokens.contains(where: { $0.hashValue == token.hashValue }) {
                    tokens.append(token)
                }
            }
        }
        
        return tokens
    }
    
    var body: some View {
        if entry.isBlocked, let startDate = entry.startDate {
            HStack(spacing: 12) {
                // Retângulo no canto esquerdo com ícones dos apps
                VStack(spacing: 6) {
                    let tokens = appTokens
                    if tokens.isEmpty {
                        Image("focca_black")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                            ForEach(Array(tokens.prefix(9)), id: \.hashValue) { token in
                                Label(token)
                                    .labelStyle(.iconOnly)
                                    .frame(width: 28, height: 28)
                                    .scaleEffect(1.2)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .frame(width: 90, height: 90)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: "2C2C2E"))
                )
                
                Spacer()
                
                // Timer à direita
                VStack(alignment: .trailing, spacing: 4) {
                    Text(timerInterval: startDate...Date.distantFuture, countsDown: false)
                        .monospacedDigit()
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Blocked")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "1C1C1E"))
            )
        } else {
            VStack(spacing: 8) {
                Image("focca_black")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                
                Text("Not Blocked")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "1C1C1E"))
            )
        }
    }
}

struct FoccaWidgetLive: Widget {
    let kind: String = "FoccaWidgetLive"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            FoccaWidgetLiveEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    FoccaWidgetLive()
} timeline: {
    SimpleEntry(date: Date(), configuration: ConfigurationAppIntent.smiley, isBlocked: false, startDate: nil as Date?, appTokenHashes: [])
}
