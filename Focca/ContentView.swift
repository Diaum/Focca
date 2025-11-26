//
//  ContentView.swift
//  Focca
//
//  Created by Fiasco on 27/10/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("onboarding_completed_email") private var onboardingCompletedEmail: String = ""
    
    var body: some View {
        Group {
            if authViewModel.isLoading && !authViewModel.isAuthenticated {
                ZStack {
                    Color(hex: "ECE8E6")
                        .ignoresSafeArea()
                    ProgressView()
                }
            } else if !authViewModel.isAuthenticated {
                NavigationView {
                    OnboardingStep4()
                        .navigationBarHidden(true)
                }
            } else {
                // Sempre mostra o onboarding quando autenticado
                NavigationView {
                    OnboardingStep1()
                        .navigationBarHidden(true)
                }
            }
        }
        .onAppear {
            // Limpa o estado de onboarding para forçar sempre mostrar
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "onboarding_completed_email")
        }
    }
}

#Preview {
    ContentView()
}
