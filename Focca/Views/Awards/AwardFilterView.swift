import SwiftUI

enum AwardFilter: String, CaseIterable {
    case all = "Todos"
    case completed = "Concluídas"
    case incomplete = "Incompletas"
}

struct AwardFilterView: View {
    @Binding var selectedFilter: AwardFilter
    let isBlocked: Bool
    let availableFilters: [AwardFilter]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableFilters, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(
                                selectedFilter == filter 
                                    ? (isBlocked ? Color(hex: "1C1C1E") : .white)
                                    : (isBlocked ? .white : Color(hex: "1C1C1E"))
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? (isBlocked ? Color.white : Color(hex: "1C1C1E")) : (isBlocked ? Color(hex: "1C1C1C") : Color.white))
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

