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
            // MARK: - Main Container
            HStack(spacing: 88) {
                // Ícone / Bloco à esquerda
                Image("focca_black")
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 58, height: 58)
                    .padding(.leading, 6)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)

                Spacer()

                // Timer centralizado verticalmente
                Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
                    .monospacedDigit()
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .frame(alignment: .center)
                    .padding(.trailing, 6)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(hex: "1C1C1E")) // tom uniforme escuro
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color(hex: "2C2C2E"), lineWidth: 1.2) // borda sutil
                    )
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
        FoccaWidgetLiveAttributes.ContentState(startDate: Date(), isActive: true)
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
