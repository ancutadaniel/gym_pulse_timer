//
//  GymPulseTimerWidgetLiveActivity.swift
//  GymPulseTimerWidget
//
//  Created by web3bit on 26.01.26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GymPulseTimerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GymPulseTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GymPulseTimerWidgetAttributes.self) { context in
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

extension GymPulseTimerWidgetAttributes {
    fileprivate static var preview: GymPulseTimerWidgetAttributes {
        GymPulseTimerWidgetAttributes(name: "World")
    }
}

extension GymPulseTimerWidgetAttributes.ContentState {
    fileprivate static var smiley: GymPulseTimerWidgetAttributes.ContentState {
        GymPulseTimerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GymPulseTimerWidgetAttributes.ContentState {
         GymPulseTimerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#if DEBUG
@available(iOS 17.2, *)
#Preview("Notification", as: .content, using: GymPulseTimerWidgetAttributes.preview) {
    GymPulseTimerWidgetLiveActivity()
} contentStates: {
    GymPulseTimerWidgetAttributes.ContentState.smiley
    GymPulseTimerWidgetAttributes.ContentState.starEyes
}
#endif
