import SwiftUI
import PhotosUI

struct ProfileHeaderView: View {
    let email: String
    let isBlocked: Bool
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImageData: Data?
    
    private var profileImageKey: String {
        "profile_image_\(email)"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                ZStack {
                    if let data = profileImageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(hex: "D0D0D7"))
                    }
                }
                .frame(width: 56, height: 56)
                .background(isBlocked ? Color(hex: "2B2B2E") : Color.white.opacity(0.9))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isBlocked ? Color.white.opacity(0.2) : Color.black.opacity(0.05), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onChange(of: selectedItem) { newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            profileImageData = data
                            saveProfileImage(data)
                        }
                    }
                }
            }
            .onAppear {
                loadProfileImage()
            }
            
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
    
    private func saveProfileImage(_ data: Data) {
        UserDefaults.standard.set(data, forKey: profileImageKey)
    }
    
    private func loadProfileImage() {
        if let data = UserDefaults.standard.data(forKey: profileImageKey) {
            profileImageData = data
        }
    }
}

