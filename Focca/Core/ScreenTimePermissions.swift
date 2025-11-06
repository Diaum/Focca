import Foundation
import FamilyControls

/// Componente responsável pelo gerenciamento de permissões de Screen Time (FamilyControls)
struct ScreenTimePermissions {
    private let authorizationCenter = AuthorizationCenter.shared
    
    /// Solicita permissão para usar Screen Time
    func requestAuthorization() async -> Bool {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            return authorizationCenter.authorizationStatus == .approved
        } catch {
            print("❌ [ScreenTimePermissions] Erro ao solicitar permissão: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Verifica o status de autorização atual
    func checkAuthorizationStatus() -> AuthorizationStatus {
        return authorizationCenter.authorizationStatus
    }
    
    /// Verifica se o Screen Time está autorizado
    func isAuthorized() -> Bool {
        return authorizationCenter.authorizationStatus == .approved
    }
}

