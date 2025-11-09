import Foundation

struct Award: Identifiable, Codable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let tint: String
    let requirement: AwardRequirement
    var isUnlocked: Bool
    
    enum AwardRequirement: Codable {
        case focusDuration(seconds: TimeInterval)
        case totalHours(hours: Int)
        case streak(days: Int)
        case scheduleSession
        case liveActivity
        case review
    }
}

