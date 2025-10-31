import Foundation
import ActivityKit

/// Gerencia o ciclo de vida da Live Activity do Focca
struct LiveActivityManager {
    static func startIfSupported(startDate: Date = Date()) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = FoccaWidgetLiveAttributes()
        let content = FoccaWidgetLiveAttributes.ContentState(startDate: startDate, isActive: true)
        do {
            _ = try Activity<FoccaWidgetLiveAttributes>.request(attributes: attributes, contentState: content)
        } catch {
            // Ignora erros silenciosamente para não quebrar o fluxo principal
        }
    }

    static func endAll() {
        let activities = Activity<FoccaWidgetLiveAttributes>.activities
        for activity in activities {
            Task { await activity.end(dismissalPolicy: .immediate) }
        }
    }
}


