//
//  ContentView.swift
//  Focca
//
//  Created by Fiasco on 27/10/25.
//

import SwiftUI

struct ContentView: View {
    @State private var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                // Se o onboarding já foi completado, mostra a view principal
                PrincipalView()
            } else {
                // Se ainda não completou, mostra o onboarding
                NavigationView {
                    OnboardingStep1()
                        .navigationBarHidden(true)
                }
                .preferredColorScheme(.light)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingCompleted"))) { _ in
            // Atualiza o estado quando o onboarding é completado
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    ContentView()
}
