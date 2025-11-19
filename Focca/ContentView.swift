//
//  ContentView.swift
//  Focca
//
//  Created by Fiasco on 27/10/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    
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
                NavigationView {
                    OnboardingStep0()
                        .navigationBarHidden(true)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
