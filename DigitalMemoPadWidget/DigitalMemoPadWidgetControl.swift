////
////  DigitalMemoPadWidgetControl.swift
////  DigitalMemoPadWidget
////
////  Created by Shuhei Kinugasa on 2025/09/28.
////
//
//import AppIntents
//import SwiftUI
//import WidgetKit
//
//struct DigitalMemoPadWidgetControl: ControlWidget {
//    var body: some ControlWidgetConfiguration {
//        StaticControlConfiguration(
//            kind: "com.shuhei.digitalmemopad.DigitalMemoPad.DigitalMemoPadWidget",
//            provider: Provider()
//        ) { value in
//            ControlWidgetToggle(
//                "Start Timer",
//                isOn: value,
//                action: StartTimerIntent()
//            ) { isRunning in
//                Label(isRunning ? "On" : "Off", systemImage: "timer")
//            }
//        }
//        .displayName("Timer")
//        .description("A an example control that runs a timer.")
//    }
//}
//
//extension DigitalMemoPadWidgetControl {
//    struct Provider: ControlValueProvider {
//        var previewValue: Bool {
//            false
//        }
//
//        func currentValue() async throws -> Bool {
//            let isRunning = true // Check if the timer is running
//            return isRunning
//        }
//    }
//}
//
//struct StartTimerIntent: SetValueIntent {
//    static let title: LocalizedStringResource = "Start a timer"
//
//    @Parameter(title: "Timer is running")
//    var value: Bool
//
//    func perform() async throws -> some IntentResult {
//        // Start / stop the timer based on `value`.
//        return .result()
//    }
//}
