import SwiftUI
import PhotosUI

struct ProfileHeaderView: View {
    let email: String
    let isBlocked: Bool
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @AppStorage("user_profile_image", store: UserDefaults(suiteName: "group.com.focca.timer")) private var profileImageData: Data?
    
    var body: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images, preferredItemEncoding: .automatic) {
                ZStack {
                    if let image = profileImage {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(hex: "D0D0D7"))
                            .padding(12)
                    }
                }
                .frame(width: 56, height: 56)
                .background(isBlocked ? Color(hex: "2B2B2E") : Color.white.opacity(0.9))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isBlocked ? Color.white.opacity(0.2) : Color.black.opacity(0.05), lineWidth: 1)
                )
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.black.opacity(0.65))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            
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
        .onChange(of: selectedPhotoItem) { newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        profileImageData = data
                    }
                }
            }
        }
    }
    
    private var profileImage: Image? {
        guard let profileImageData,
              let uiImage = UIImage(data: profileImageData) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}

