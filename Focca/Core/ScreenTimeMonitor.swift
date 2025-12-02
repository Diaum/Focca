import Foundation
import UIKit
import FamilyControls
import ManagedSettings
import Combine

/// Monitora o status do Screen Time e notifica quando é desativado
class ScreenTimeMonitor: ObservableObject {
    static let shared = ScreenTimeMonitor()
    
    @Published var isScreenTimeAuthorized: Bool = true
    @Published var shouldBlockApp: Bool = false
    
    private let authorizationCenter = AuthorizationCenter.shared
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAuthorizationStatus()
        startMonitoring()
        
        // Observa mudanças no status de autorização
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.checkAuthorizationStatus()
            }
            .store(in: &cancellables)
    }
    
    /// Verifica o status atual de autorização
    func checkAuthorizationStatus() {
        let status = authorizationCenter.authorizationStatus
        let wasAuthorized = isScreenTimeAuthorized
        isScreenTimeAuthorized = (status == .approved)
        shouldBlockApp = !isScreenTimeAuthorized
        
        if wasAuthorized != isScreenTimeAuthorized {
            print("⚠️ [ScreenTimeMonitor] Status mudou: \(isScreenTimeAuthorized ? "Autorizado" : "NÃO Autorizado")")
            
            if !isScreenTimeAuthorized {
                // Limpa bloqueios ativos se o Screen Time foi desativado
                clearActiveBlocking()
            }
        }
    }
    
    /// Inicia monitoramento periódico (verifica a cada 5 segundos)
    private func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkAuthorizationStatus()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    /// Para o monitoramento
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Limpa bloqueios ativos quando Screen Time é desativado
    private func clearActiveBlocking() {
        let store = ManagedSettingsStore()
        store.application.blockedApplications = nil
        store.shield.applicationCategories = nil
        store.webContent.blockedByFilter = nil
        
        // Limpa dados de bloqueio
        let sharedDefaults = UserDefaults(suiteName: "group.com.focca.timer") ?? UserDefaults.standard
        sharedDefaults.removeObject(forKey: "blocked_start_date")
        sharedDefaults.synchronize()
        UserDefaults.standard.removeObject(forKey: "blocked_start_date")
        
        print("🧹 [ScreenTimeMonitor] Bloqueios limpos devido à desativação do Screen Time")
    }
    
    deinit {
        stopMonitoring()
    }
}

