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
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .background:
                        // Save any pending changes when app goes to background
                        saveContext()
                        print("🔄 App moved to background - saving context")
                    case .inactive:
                        // Also save when app becomes inactive (e.g., app switcher)
                        saveContext()
                        print("🔄 App became inactive - saving context")
                    case .active:
                        print("🔄 App became active")
                    @unknown default:
                        break
                    }
                }
        }
    }
    
    private func saveContext() {
        let context = persistenceController.container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Successfully saved Core Data context")
            } catch {
                print("❌ Error saving Core Data context: \(error)")
            }
        } else {
            print("ℹ️ No changes to save")
        }
    }
}
