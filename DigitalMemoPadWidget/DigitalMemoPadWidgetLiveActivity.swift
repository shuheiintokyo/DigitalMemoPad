////
////  DigitalMemoPadWidgetLiveActivity.swift
////  DigitalMemoPadWidget
////
////  Created by Shuhei Kinugasa on 2025/09/28.
////
//
//import ActivityKit
//import WidgetKit
//import SwiftUI
//
//struct DigitalMemoPadWidgetAttributes: ActivityAttributes {
//    public struct ContentState: Codable, Hashable {
//        // Dynamic stateful properties about your activity go here!
//        var emoji: String
//    }
//
//    // Fixed non-changing properties about your activity go here!
//    var name: String
//}
//
//struct DigitalMemoPadWidgetLiveActivity: Widget {
//    var body: some WidgetConfiguration {
//        ActivityConfiguration(for: DigitalMemoPadWidgetAttributes.self) { context in
//            // Lock screen/banner UI goes here
//            VStack {
//                Text("Hello \(context.state.emoji)")
//            }
//            .activityBackgroundTint(Color.cyan)
//            .activitySystemActionForegroundColor(Color.black)
//
//        } dynamicIsland: { context in
//            DynamicIsland {
//                // Expanded UI goes here.  Compose the expanded UI through
//                // various regions, like leading/trailing/center/bottom
//                DynamicIslandExpandedRegion(.leading) {
//                    Text("Leading")
//                }
//                DynamicIslandExpandedRegion(.trailing) {
//                    Text("Trailing")
//                }
//                DynamicIslandExpandedRegion(.bottom) {
//                    Text("Bottom \(context.state.emoji)")
//                    // more content
//                }
//            } compactLeading: {
//                Text("L")
//            } compactTrailing: {
//                Text("T \(context.state.emoji)")
//            } minimal: {
//                Text(context.state.emoji)
//            }
//            .widgetURL(URL(string: "http://www.apple.com"))
//            .keylineTint(Color.red)
//        }
//    }
//}
//
//extension DigitalMemoPadWidgetAttributes {
//    fileprivate static var preview: DigitalMemoPadWidgetAttributes {
//        DigitalMemoPadWidgetAttributes(name: "World")
//    }
//}
//
//extension DigitalMemoPadWidgetAttributes.ContentState {
//    fileprivate static var smiley: DigitalMemoPadWidgetAttributes.ContentState {
//        DigitalMemoPadWidgetAttributes.ContentState(emoji: "😀")
//     }
//     
//     fileprivate static var starEyes: DigitalMemoPadWidgetAttributes.ContentState {
//         DigitalMemoPadWidgetAttributes.ContentState(emoji: "🤩")
//     }
//}
//
//#Preview("Notification", as: .content, using: DigitalMemoPadWidgetAttributes.preview) {
//   DigitalMemoPadWidgetLiveActivity()
//} contentStates: {
//    DigitalMemoPadWidgetAttributes.ContentState.smiley
//    DigitalMemoPadWidgetAttributes.ContentState.starEyes
//}
