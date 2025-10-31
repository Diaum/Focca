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
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image("focca_black")
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focca ativo")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Apps bloqueados")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "8A8A8E"))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
                            .monospacedDigit()
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)

                        Text("tempo decorrido")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color(hex: "8A8A8E"))
                            .textCase(.uppercase)
                            .kerning(0.5)
                    }


                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "1A1A1C"), Color(hex: "0A0A0A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color(hex: "FF6B6B").opacity(0.8), lineWidth: 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
            )
            .activityBackgroundTint(Color.clear)
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
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