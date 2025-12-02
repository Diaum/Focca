import SwiftUI

struct ContentView: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @ObservedObject private var screenTimeMonitor = ScreenTimeMonitor.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("onboarding_completed_email") private var onboardingCompletedEmail: String = ""
    
    var body: some View {
        Group {
            // PRIORIDADE 1: Verifica se Screen Time está ativo (bloqueia tudo se não estiver)
            if screenTimeMonitor.shouldBlockApp {
                ScreenTimeRequiredView()
            }
            // PRIORIDADE 2: Onboarding
            else if !hasCompletedOnboardingForCurrentUser {
                NavigationView {
                    OnboardingStep1()
                        .navigationBarHidden(true)
                }
            }
            // PRIORIDADE 3: Autenticação
            else if !authViewModel.isAuthenticated {
                NavigationView {
                    OnboardingStep4()
                        .navigationBarHidden(true)
                }
                .id("auth_flow")
            }
            // PRIORIDADE 4: App principal
            else {
                PrincipalView()
            }
        }
        .onAppear {
            // Verifica status do Screen Time quando o app aparece
            screenTimeMonitor.checkAuthorizationStatus()
        }
    }
    
    private var hasCompletedOnboardingForCurrentUser: Bool {
        guard let email = authViewModel.currentEmail else {
            return false
        }
        return hasCompletedOnboarding && onboardingCompletedEmail == email
    }
}

#Preview {
    ContentView()
}
