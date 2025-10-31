import SwiftUI

struct AwardsView: View {
    @Binding var selectedTab: Int

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 120)
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                Spacer()
                WhiteRoundedBottomPlain()
                TabBar(selectedTab: $selectedTab)
                    .padding(.bottom, 0)
            }
        }
        .preferredColorScheme(.light)
    }
}

struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView(selectedTab: .constant(2))
            .preferredColorScheme(.light)
    }
}


