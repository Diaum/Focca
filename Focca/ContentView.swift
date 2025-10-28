//
//  ContentView.swift
//  Focca
//
//  Created by Fiasco on 27/10/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            OnboardingStep1()
                .navigationBarHidden(true)
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
