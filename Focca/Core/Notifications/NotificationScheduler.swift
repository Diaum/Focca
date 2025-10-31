import Foundation
import UserNotifications

/// Componente responsável pelo agendamento de notificações
class NotificationScheduler {
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// Agenda uma notificação para um dia específico da semana
    /// - Parameters:
    ///   - schedule: O schedule que vai começar
    ///   - weekday: Dia da semana (1=Dom, 2=Seg, ..., 7=Sáb)
    func scheduleNotificationForWeekday(schedule: ScheduleModel, weekday: Int) {
        // Calcula o horário da notificação (10 minutos antes)
        let notificationTime = calculateNotificationTime(for: schedule.startTime)
        
        // Cria o conteúdo da notificação
        let content = NotificationContent.createScheduleNotification(for: schedule)
        
        // Cria o trigger semanal
        let trigger = createWeeklyTrigger(hour: notificationTime.hour, minute: notificationTime.minute, weekday: weekday)
        
        // Identificador único: scheduleId + weekday
        let identifier = "schedule_\(schedule.id)_weekday_\(weekday)"
        
        // Cria e agenda a requisição
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ [NotificationScheduler] Erro ao agendar: \(error.localizedDescription)")
                print("   Schedule ID: \(schedule.id)")
                print("   Weekday: \(weekday)")
                print("   Time: \(String(format: "%02d:%02d", notificationTime.hour, notificationTime.minute))")
            } else {
                let weekdayName = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][(weekday - 1) % 7]
                print("✅ [NotificationScheduler] Agendada para \(weekdayName) às \(String(format: "%02d:%02d", notificationTime.hour, notificationTime.minute))")
                print("   Schedule ID: \(schedule.id)")
                print("   Schedule Mode: \(schedule.modeName)")
                print("   Trigger repeats: true")
                
                // Verifica se foi realmente agendada
                self.notificationCenter.getPendingNotificationRequests { requests in
                    let found = requests.contains { $0.identifier == identifier }
                    if found {
                        print("   ✅ Confirmado: Notificação encontrada nas pendentes")
                    } else {
                        print("   ⚠️ AVISO: Notificação não encontrada nas pendentes!")
                    }
                }
            }
        }
    }
    
    /// Calcula o horário da notificação (10 minutos antes do início)
    /// - Parameter startTime: Horário de início do schedule
    /// - Returns: Tupla com hora e minuto da notificação
    private func calculateNotificationTime(for startTime: Date) -> (hour: Int, minute: Int) {
        let calendar = Calendar.current
        let startComps = calendar.dateComponents([.hour, .minute], from: startTime)
        guard let startHour = startComps.hour, let startMin = startComps.minute else {
            return (9, 50) // Default: 09:50
        }
        
        // Calcula 10 minutos antes
        var notificationHour = startHour
        var notificationMinute = startMin - 10
        
        // Se o minuto for negativo, ajusta para o dia anterior (hora anterior)
        if notificationMinute < 0 {
            notificationHour = (startHour - 1 + 24) % 24
            notificationMinute = startMin + 50
        }
        
        return (notificationHour, notificationMinute)
    }
    
    /// Cria um trigger semanal que repete toda semana
    /// - Parameters:
    ///   - hour: Hora da notificação
    ///   - minute: Minuto da notificação
    ///   - weekday: Dia da semana (1=Dom, 2=Seg, ..., 7=Sáb)
    /// - Returns: Trigger configurado para repetição semanal
    private func createWeeklyTrigger(hour: Int, minute: Int, weekday: Int) -> UNCalendarNotificationTrigger {
        var triggerComps = DateComponents()
        triggerComps.weekday = weekday
        triggerComps.hour = hour
        triggerComps.minute = minute
        
        return UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: true)
    }
    
    /// Cancela todas as notificações de um schedule específico
    func cancelNotifications(for scheduleId: String) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { $0.identifier.hasPrefix("schedule_\(scheduleId)_weekday_") }
                .map { $0.identifier }
            
            if !identifiersToCancel.isEmpty {
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
                print("🗑️ [NotificationScheduler] Canceladas \(identifiersToCancel.count) notificação(ões) para schedule '\(scheduleId)'")
            }
        }
    }
    
    /// Cancela todas as notificações pendentes
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ [NotificationScheduler] Todas as notificações foram canceladas")
    }
    
    /// Agenda notificação para HOJE se o schedule começar hoje e estiver nos weekdays
    /// IMPORTANTE: Só agenda se NÃO houver notificação semanal que já cobre hoje
    func scheduleNotificationForTodayIfNeeded(schedule: ScheduleModel) {
        let calendar = Calendar.current
        let now = Date()
        let todayWeekday = calendar.component(.weekday, from: now)
        
        // Verifica se hoje está nos dias do schedule
        guard schedule.weekdays.contains(todayWeekday) else {
            print("   ℹ️ [NotificationScheduler] Hoje não está nos dias do schedule")
            return
        }
        
        // Extrai hora/minuto do início do schedule
        let startComps = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
        guard let startHour = startComps.hour, let startMin = startComps.minute else {
            return
        }
        
        // Calcula o horário da notificação (10 minutos antes)
        let notificationTime = calculateNotificationTime(for: schedule.startTime)
        let notificationHour = notificationTime.hour
        let notificationMinute = notificationTime.minute
        
        // Verifica se já existe uma notificação semanal pendente para hoje com o mesmo horário
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            
            let weeklyNotificationId = "schedule_\(schedule.id)_weekday_\(todayWeekday)"
            let hasWeeklyNotification = requests.contains { req in
                if req.identifier == weeklyNotificationId {
                    // Verifica se o trigger semanal vai disparar hoje
                    if let calendarTrigger = req.trigger as? UNCalendarNotificationTrigger {
                        let triggerComps = calendarTrigger.dateComponents
                        // Se weekday, hour e minute coincidem, a notificação semanal já vai disparar hoje
                        if triggerComps.weekday == todayWeekday &&
                           triggerComps.hour == notificationHour &&
                           triggerComps.minute == notificationMinute {
                            print("   ℹ️ [NotificationScheduler] Notificação semanal já cobre hoje, não criando duplicata")
                            return true
                        }
                    }
                }
                return false
            }
            
            // Se já existe notificação semanal que cobre hoje, não cria adicional
            if hasWeeklyNotification {
                print("   ℹ️ [NotificationScheduler] Notificação semanal já agendada para hoje, pulando notificação específica")
                return
            }
            
            // Cria a data de início para hoje
            guard let scheduleStartToday = calendar.date(bySettingHour: startHour, minute: startMin, second: 0, of: now) else {
                return
            }
            
            // Calcula quantos minutos faltam até o início
            let minutesUntilStart = scheduleStartToday.timeIntervalSince(now) / 60.0
            
            // Se já passou o horário hoje, não agenda (espera a notificação semanal)
            if minutesUntilStart < 0 {
                print("   ℹ️ [NotificationScheduler] Horário do schedule já passou hoje")
                return
            }
            
            print("   📅 [NotificationScheduler] Schedule começa em \(Int(minutesUntilStart)) minutos hoje")
            
            // Se começar em menos de 10 minutos, envia notificação IMEDIATA (mas só se não houver semanal)
            if minutesUntilStart < 10 {
                print("   ⚡ [NotificationScheduler] Schedule começa em menos de 10 minutos! Enviando notificação IMEDIATA")
                self.sendImmediateNotificationForSchedule(schedule: schedule)
                return
            }
            
            // Verifica se o horário da notificação ainda não passou hoje
            let notificationMinutes = Double(notificationHour * 60 + notificationMinute)
            let currentMinutes = Double(calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now))
            
            if notificationMinutes > currentMinutes || (notificationHour == 0 && notificationMinute < 10) {
                // Cria trigger para hoje específico
                var dateComps = calendar.dateComponents([.year, .month, .day], from: now)
                dateComps.hour = notificationHour
                dateComps.minute = notificationMinute
                dateComps.second = 0
                
                guard let notificationDate = calendar.date(from: dateComps) else {
                    return
                }
                
                // Se a data já passou, não agenda
                if notificationDate <= now {
                    print("   ℹ️ [NotificationScheduler] Horário da notificação já passou hoje")
                    return
                }
                
                let timeInterval = notificationDate.timeIntervalSince(now)
                
                // Cria conteúdo da notificação
                let content = NotificationContent.createScheduleNotification(for: schedule)
                
                // Trigger para data específica (não repete, só hoje)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                
                // Identificador único para hoje
                let identifier = "schedule_\(schedule.id)_today_\(calendar.startOfDay(for: now).timeIntervalSince1970)"
                
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                self.notificationCenter.add(request) { error in
                    if let error = error {
                        print("   ❌ [NotificationScheduler] Erro ao agendar notificação para hoje: \(error.localizedDescription)")
                    } else {
                        print("   ✅ [NotificationScheduler] Notificação agendada para hoje às \(String(format: "%02d:%02d", notificationHour, notificationMinute))")
                        print("      Faltam \(Int(minutesUntilStart)) minutos para o schedule começar")
                    }
                }
            } else {
                print("   ℹ️ [NotificationScheduler] Horário da notificação já passou hoje, será agendada para a próxima semana")
            }
        }
    }
    
    /// Envia notificação IMEDIATA para schedule que começa em menos de 10 minutos
    private func sendImmediateNotificationForSchedule(schedule: ScheduleModel) {
        let content = NotificationContent.createScheduleNotification(for: schedule)
        
        // Trigger imediato (1 segundo)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Identificador único
        let identifier = "schedule_\(schedule.id)_immediate_\(Date().timeIntervalSince1970)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("   ❌ [NotificationScheduler] Erro ao enviar notificação imediata: \(error.localizedDescription)")
            } else {
                print("   ✅ [NotificationScheduler] Notificação IMEDIATA enviada para schedule '\(schedule.modeName)'")
            }
        }
    }
}

