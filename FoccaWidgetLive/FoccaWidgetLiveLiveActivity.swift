//
//  FoccaWidgetLiveLiveActivity.swift
//  FoccaWidgetLive
//
//  Created by Fiasco on 30/10/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FoccaWidgetLiveLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FoccaWidgetLiveAttributes.self) { context in
            HStack(spacing: 0) {
                Image("focca-rectangle-gray", bundle: Bundle.main)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 58, height: 58)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .padding(.leading, 18)

                Spacer(minLength: 180)

                Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
                    .monospacedDigit()
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.trailing, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(hex: "1C1C1E"))
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            )
            .activityBackgroundTint(Color.clear)
            .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
}

extension FoccaWidgetLiveAttributes {
    fileprivate static var preview: FoccaWidgetLiveAttributes {
        FoccaWidgetLiveAttributes()
    }
}

extension FoccaWidgetLiveAttributes.ContentState {
    fileprivate static var active: FoccaWidgetLiveAttributes.ContentState {
        // Para mostrar 15h30m56s, a data de início deve ser 15h30m56s atrás
        let hours = 10
        let minutes = 30
        let seconds = 56
        let totalSeconds = hours * 3600 + minutes * 60 + seconds
        let startDate = Date().addingTimeInterval(-TimeInterval(totalSeconds))
        return FoccaWidgetLiveAttributes.ContentState(startDate: startDate, isActive: true)
    }

    fileprivate static var paused: FoccaWidgetLiveAttributes.ContentState {
        FoccaWidgetLiveAttributes.ContentState(startDate: Date().addingTimeInterval(-3600), isActive: false)
    }
}

#Preview("Lock Screen", as: .content, using: FoccaWidgetLiveAttributes.preview) {
   FoccaWidgetLiveLiveActivity()
} contentStates: {
    FoccaWidgetLiveAttributes.ContentState.active
}
