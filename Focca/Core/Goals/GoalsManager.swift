import Foundation

class GoalsManager {
    static let shared = GoalsManager()
    
    private let userDefaults = UserDefaults.standard
    private let goalsEnabledKey = "goals_enabled"
    
    private init() {
        // Initialize goals as enabled by default if not set
        if userDefaults.object(forKey: goalsEnabledKey) == nil {
            userDefaults.set(true, forKey: goalsEnabledKey)
        }
    }
    
    var areGoalsEnabled: Bool {
        get {
            return userDefaults.bool(forKey: goalsEnabledKey)
        }
        set {
            userDefaults.set(newValue, forKey: goalsEnabledKey)
            NotificationCenter.default.post(name: NSNotification.Name("GoalsEnabledChanged"), object: nil)
        }
    }
}

