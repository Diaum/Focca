import Foundation

// Modelo de dados para um agendamento (schedule)
struct ScheduleModel: Codable, Identifiable {
    var id: String
    var modeName: String
    var weekdays: Set<Int> // 1=Dom, 2=Seg, ..., 7=Sáb (Calendar.component)
    var startTime: Date // Horário de início (só hora/minuto importam)
    var endTime: Date // Horário de fim (só hora/minuto importam)
    var isActive: Bool // Se o schedule está ativo (pode ser desativado temporariamente)
    var createdAt: Date
    
    // Para Codable, converte Set<Int> para Array<Int>
    enum CodingKeys: String, CodingKey {
        case id, modeName, weekdays, startTime, endTime, isActive, createdAt
    }
    
    init(
        modeName: String,
        weekdays: Set<Int>,
        startTime: Date,
        endTime: Date,
        isActive: Bool = true
    ) {
        self.id = UUID().uuidString
        self.modeName = modeName
        self.weekdays = weekdays
        self.startTime = startTime
        self.endTime = endTime
        self.isActive = isActive
        self.createdAt = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        modeName = try container.decode(String.self, forKey: .modeName)
        let weekdaysArray = try container.decode([Int].self, forKey: .weekdays)
        weekdays = Set(weekdaysArray)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(modeName, forKey: .modeName)
        try container.encode(Array(weekdays), forKey: .weekdays)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
    }

    // Valida se o schedule é válido (mínimo 5 minutos, pelo menos 1 dia da semana)
    func isValid() -> Bool {
        guard weekdays.count >= 1 else { return false }
        let calendar = Calendar.current
        let startComps = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComps = calendar.dateComponents([.hour, .minute], from: endTime)
        let start = calendar.date(bySettingHour: startComps.hour ?? 0, minute: startComps.minute ?? 0, second: 0, of: Date()) ?? Date()
        let end = calendar.date(bySettingHour: endComps.hour ?? 0, minute: endComps.minute ?? 0, second: 0, of: Date()) ?? Date()
        let duration = end.timeIntervalSince(start)
        // Se endTime < startTime, assume que vai até o próximo dia
        let actualDuration = duration < 0 ? duration + 86400 : duration
        return actualDuration >= 300 // Mínimo 5 minutos (300 segundos)
    }

    // Verifica se o schedule deve estar ativo neste momento
    func shouldBeActiveNow() -> Bool {
        guard isActive else {
            print("      ❌ Schedule inativo")
            return false
        }
        guard isValid() else {
            print("      ❌ Schedule inválido")
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now) // 1=Dom, 2=Seg, ...
        
        guard weekdays.contains(weekday) else {
            print("      ❌ Hoje não está nos dias do schedule (hoje=\(weekday), schedule=\(weekdays.sorted()))")
            return false
        }
        
        let startComps = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComps = calendar.dateComponents([.hour, .minute], from: endTime)
        let currentComps = calendar.dateComponents([.hour, .minute], from: now)
        
        guard let startHour = startComps.hour,
              let startMin = startComps.minute,
              let endHour = endComps.hour,
              let endMin = endComps.minute,
              let currHour = currentComps.hour,
              let currMin = currentComps.minute else {
            print("      ❌ Erro ao extrair componentes de data")
            return false
        }
        
        let currentMinutes = currHour * 60 + currMin
        let startMinutes = startHour * 60 + startMin
        let endMinutes = endHour * 60 + endMin
        
        print("      - Horário atual: \(String(format: "%02d:%02d", currHour, currMin)) (\(currentMinutes) min)")
        print("      - Horário início: \(String(format: "%02d:%02d", startHour, startMin)) (\(startMinutes) min)")
        print("      - Horário fim: \(String(format: "%02d:%02d", endHour, endMin)) (\(endMinutes) min)")
        
        // Se end < start, assume que vai até o próximo dia
        if endMinutes < startMinutes {
            let isActive = currentMinutes >= startMinutes || currentMinutes < endMinutes
            print("      - Horário cruza meia-noite: \(isActive ? "✅ ATIVO" : "❌ INATIVO")")
            return isActive
        } else {
            let isActive = currentMinutes >= startMinutes && currentMinutes < endMinutes
            print("      - Horário no mesmo dia: \(isActive ? "✅ ATIVO" : "❌ INATIVO")")
            return isActive
        }
    }
}

