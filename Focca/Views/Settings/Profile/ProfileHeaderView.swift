import SwiftUI

struct ProfileHeaderView: View {
    let email: String
    let isBlocked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(hex: "D0D0D7"))
                .frame(width: 56, height: 56)
                .background(isBlocked ? Color(hex: "2B2B2E") : Color.white.opacity(0.9))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isBlocked ? Color.white.opacity(0.2) : Color.black.opacity(0.05), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Perfil")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "8A8A8E"))
                
                Text(email)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(isBlocked ? .white : Color(hex: "1C1C1E"))
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

