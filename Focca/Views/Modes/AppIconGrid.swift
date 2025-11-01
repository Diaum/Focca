import SwiftUI
import FamilyControls

struct AppIconGrid: View {
    let selection: FamilyActivitySelection
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Items Selected")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "1C1C1E"))

                    let categoryCount = selection.categoryTokens.count
                    let appCount = selection.applicationTokens.count
                    let totalCount = CategoryExpander.totalItemCount(selection)

                    if totalCount > 0 {
                        HStack(spacing: 6) {
                            if categoryCount > 0 {
                                Text("\(categoryCount) \(categoryCount == 1 ? "category" : "categories")")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "007AFF"))
                            }
                            if categoryCount > 0 && appCount > 0 {
                                Text("•")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            if appCount > 0 {
                                Text("\(appCount) \(appCount == 1 ? "app" : "apps")")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Text("Nothing selected")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    let totalCount = CategoryExpander.totalItemCount(selection)
                    if totalCount > 0 {
                        // Show app icons (limit to 24 for better UX)
                        ForEach(Array(selection.applicationTokens.prefix(24)), id: \.hashValue) { token in
                            Label(token)
                                .labelStyle(.iconOnly)
                                .frame(width: 48, height: 48)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }

                        // Show category icons with real category icons
                        let categoriesAvailable = max(0, min(selection.categoryTokens.count, 24 - selection.applicationTokens.count))
                        ForEach(Array(selection.categoryTokens.prefix(categoriesAvailable)), id: \.hashValue) { categoryToken in
                            Label(categoryToken)
                                .labelStyle(.iconOnly)
                                .frame(width: 48, height: 48)
                                .background(Color(hex: "F0F8FF"))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                    } else {
                        ForEach(0..<8, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: "F5F5F5"))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: "C6C6C8"))
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
    }
}

#Preview {
    let selection = FamilyActivitySelection()
    return AppIconGrid(selection: selection)
        .padding()
        .background(Color.gray.opacity(0.1))
}

