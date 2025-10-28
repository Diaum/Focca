import SwiftUI

struct ModeSelectionSheet: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F7F7F8"), Color(hex: "ECECEC")],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "1C1C1E"))
                            .frame(width: 34, height: 34)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Text("Select mode")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "1C1C1E"))

                VStack(spacing: 14) {
                    ModeRow(title: "Allow", isSelected: false)
                    ModeRow(title: "Work", isSelected: false)
                    ModeRow(title: "Family", isSelected: true)
                    CreateModeRow()
                }
                .padding(.horizontal, 20)

                Spacer()

                Button(action: {}) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "DAD7D6"))
                        .cornerRadius(20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct ModeRow: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Color(hex: "1C1C1E"))
            Spacer()
            Button("Edit", action: {})
                .foregroundColor(Color(hex: "1C1C1E"))
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.white : Color(hex: "EDEBEA"))
        )
    }
}

private struct CreateModeRow: View {
    var body: some View {
        HStack {
            Text("Create new mode")
                .foregroundColor(Color(hex: "1C1C1E"))
            Spacer()
            Image(systemName: "plus")
                .foregroundColor(Color(hex: "1C1C1E"))
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "EDEBEA"))
        )
    }
}

#Preview {
    ModeSelectionSheet()
}


