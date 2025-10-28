import SwiftUI
import Combine
import FamilyControls

class SelectionModel: ObservableObject {
    @Published var selection = FamilyActivitySelection()
    
    init() {
        loadSelection()
    }
    
    private func loadSelection() {
        if let data = UserDefaults.standard.data(forKey: "familyActivitySelection"),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
        }
    }
}

