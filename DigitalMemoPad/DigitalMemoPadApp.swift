//
//  DigitalMemoPadApp.swift
//  DigitalMemoPad
//
//  Created by Shuhei Kinugasa on 2025/09/28.
//

import SwiftUI

@main
struct DigitalMemoPadApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
