//
//  FoccaWidgetLiveLiveActivity.swift
//  FoccaWidgetLive
//
//  Created by Fiasco on 30/10/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FoccaWidgetLiveAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FoccaWidgetLiveLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FoccaWidgetLiveAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FoccaWidgetLiveAttributes {
    fileprivate static var preview: FoccaWidgetLiveAttributes {
        FoccaWidgetLiveAttributes(name: "World")
    }
}

extension FoccaWidgetLiveAttributes.ContentState {
    fileprivate static var smiley: FoccaWidgetLiveAttributes.ContentState {
        FoccaWidgetLiveAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FoccaWidgetLiveAttributes.ContentState {
         FoccaWidgetLiveAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FoccaWidgetLiveAttributes.preview) {
   FoccaWidgetLiveLiveActivity()
} contentStates: {
    FoccaWidgetLiveAttributes.ContentState.smiley
    FoccaWidgetLiveAttributes.ContentState.starEyes
}
