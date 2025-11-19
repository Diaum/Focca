import Foundation
import UserNotifications
import UIKit

/// Componente responsável por criar o conteúdo das notificações
struct NotificationContent {
    /// Cria o conteúdo de uma notificação de schedule
    /// - Parameter schedule: O schedule que vai começar
    /// - Returns: Conteúdo configurado seguindo as melhores práticas da Apple
    static func createScheduleNotification(for schedule: ScheduleModel) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Título claro e conciso (melhor prática Apple)
        content.title = "Agendamento Começando em Breve"
        
        // Mensagem personalizada com o nome do modo
        content.body = "Seu agendamento '\(schedule.modeName)' começa em 10 minutos"
        
        // Som padrão do sistema
        content.sound = .default
        
        // Badge atualizado
        content.badge = 1
        
        // Categoria para possíveis ações (abrir app / iniciar agora)
        content.categoryIdentifier = "SCHEDULE_REMINDER"
        
        // Adiciona o ícone do app (thumbnail)
        // iOS não permite attachments muito pequenos, então vamos usar uma imagem maior
        // Tenta obter o ícone do app de diferentes formas
        var appIconImage: UIImage? = nil
        
        // Método 1: Tenta carregar do bundle principal
        if let icon = UIImage(named: "AppIcon") {
            appIconImage = icon
        } else if let icon = UIImage(named: "AppIcon-1024") {
            appIconImage = icon
        } else if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png"),
                  let icon = UIImage(contentsOfFile: iconPath) {
            appIconImage = icon
        } else {
            // Método 2: Tenta obter do Info.plist
            if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
               let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
               let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
               let lastIcon = iconFiles.last,
               let icon = UIImage(named: lastIcon) {
                appIconImage = icon
            }
        }
        
        // Para notificações, o iOS requer imagens maiores (mínimo 300x300px)
        // Redimensiona o ícone se necessário
        if let appIcon = appIconImage {
            let minSize: CGFloat = 300
            let resizedIcon: UIImage
            
            if appIcon.size.width < minSize || appIcon.size.height < minSize {
                // Redimensiona para pelo menos 300x300
                let scale = max(minSize / appIcon.size.width, minSize / appIcon.size.height)
                let newSize = CGSize(width: appIcon.size.width * scale, height: appIcon.size.height * scale)
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                appIcon.draw(in: CGRect(origin: .zero, size: newSize))
                resizedIcon = UIGraphicsGetImageFromCurrentImageContext() ?? appIcon
                UIGraphicsEndImageContext()
            } else {
                resizedIcon = appIcon
            }
            
            if let imageURL = saveImageToTempDirectory(resizedIcon) {
                if let attachment = try? UNNotificationAttachment(
                    identifier: "appIcon",
                    url: imageURL,
                    options: [
                        UNNotificationAttachmentOptionsTypeHintKey: "public.png"
                    ]
                ) {
                    content.attachments = [attachment]
                }
            }
        }
        
        return content
    }

    /// Conteúdo para notificação no horário exato do início
    static func createScheduleStartNowNotification(for schedule: ScheduleModel) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Agora é hora de FOCCAR!"
        content.body = "O Focca ja vai ativar, o modo '\(schedule.modeName)' está começando agora"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "SCHEDULE_START_NOW"
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // Adiciona userInfo para ativação automática em background
        content.userInfo = [
            "action": "ACTIVATE_SCHEDULE",
            "scheduleId": schedule.id,
            "scheduleModeName": schedule.modeName
        ]
        
        return content
    }
    
    /// Helper para salvar imagem em diretório temporário para usar como attachment
    private static func saveImageToTempDirectory(_ image: UIImage) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let imageURL = tempDir.appendingPathComponent("appIcon_\(UUID().uuidString).png")
        
        guard let imageData = image.pngData() else {
            return nil
        }
        
        do {
            try imageData.write(to: imageURL)
            return imageURL
        } catch {
            print("❌ Erro ao salvar imagem temporária: \(error.localizedDescription)")
            return nil
        }
    }
}

