import SwiftUI

enum AwardFilter: String, CaseIterable {
    case all = "All"
    case incomplete = "Incomplete"
    case completed = "Completed"
}

struct AwardFilterView: View {
    @Binding var selectedFilter: AwardFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AwardFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedFilter == filter ? .white : Color(hex: "1C1C1E"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? Color(hex: "1C1C1E") : Color.white)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

