import SwiftUI

struct ContentView: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("onboarding_completed_email") private var onboardingCompletedEmail: String = ""
    
    var body: some View {
        Group {
            if !authViewModel.isAuthenticated {
                NavigationView {
                    OnboardingStep4()
                        .navigationBarHidden(true)
                }
                .id("auth_flow")
            } else if !hasCompletedOnboardingForCurrentUser {
                NavigationView {
                    OnboardingStep1()
                        .navigationBarHidden(true)
                }
            } else {
                PrincipalView()
            }
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
