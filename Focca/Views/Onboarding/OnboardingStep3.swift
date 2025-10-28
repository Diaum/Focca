import SwiftUI

struct OnboardingStep3: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            Text("Step 3")
                .font(.system(size: 32, weight: .bold))
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    OnboardingStep3()
}

