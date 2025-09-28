//
//  Persistence.swift
//  DigitalMemoPad
//

import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews
        for i in 0..<3 {
            let newMemo = Item(context: viewContext)
            newMemo.timestamp = Date().addingTimeInterval(TimeInterval(-i * 3600))
            newMemo.content = "Sample memo \(i + 1)\nThis is sample content for preview."
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DigitalMemoPad")
        
        print("\n🔷 ========== MAIN APP CORE DATA INIT ==========")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            print("📝 Using in-memory store (preview/testing)")
        } else {
            // Configure for App Group sharing
            let storeURL = URL.storeURL(for: "group.com.shuhei.digitalmemopad", databaseName: "DigitalMemoPad")
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [storeDescription]
            
            print("📂 Main app attempting to use store at: \(storeURL.path)")
            
            // Check if file exists before loading
            let fileManager = FileManager.default
            let fileExists = fileManager.fileExists(atPath: storeURL.path)
            print("📁 SQLite file exists: \(fileExists ? "YES ✅" : "NO ❌ (will be created)")")
            
            if fileExists {
                let attributes = try? fileManager.attributesOfItem(atPath: storeURL.path)
                let fileSize = attributes?[.size] as? Int64 ?? 0
                print("📏 File size: \(fileSize) bytes")
                let modificationDate = attributes?[.modificationDate] as? Date ?? Date()
                print("📅 Last modified: \(modificationDate)")
            }
            
            // Check App Group container
            if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.shuhei.digitalmemopad") {
                print("📱 App Group container path: \(containerURL.path)")
                print("📱 Container exists: \(fileManager.fileExists(atPath: containerURL.path) ? "YES ✅" : "NO ❌")")
                
                // List all SQLite files in the container
                if let contents = try? fileManager.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil) {
                    let sqliteFiles = contents.filter { $0.pathExtension == "sqlite" || $0.pathExtension == "sqlite-shm" || $0.pathExtension == "sqlite-wal" }
                    print("📄 SQLite files in container:")
                    for file in sqliteFiles {
                        let attributes = try? fileManager.attributesOfItem(atPath: file.path)
                        let fileSize = attributes?[.size] as? Int64 ?? 0
                        print("   - \(file.lastPathComponent): \(fileSize) bytes")
                    }
                }
            } else {
                print("❌ ERROR: Could not access App Group container!")
                print("⚠️ Make sure the App Group 'group.com.shuhei.digitalmemopad' is configured in:")
                print("   1. Main app entitlements")
                print("   2. Widget extension entitlements")
                print("   3. Apple Developer account")
            }
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("❌ Main app Core Data error: \(error)")
                print("   Error details: \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("✅ Main app Core Data loaded successfully")
                print("💾 Store URL: \(storeDescription.url?.absoluteString ?? "unknown")")
                print("📝 Store type: \(storeDescription.type)")
                
                // Perform initial count - using container directly instead of self
                let request = NSFetchRequest<Item>(entityName: "Item")
                if let count = try? self.container.viewContext.count(for: request) {
                    print("📊 Initial memo count: \(count)")
                }
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        print("🔄 Auto-merge from parent context: ENABLED")
        print("🔷 =============================================\n")
    }
}

// MARK: - App Group Support
extension URL {
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            print("❌ CRITICAL ERROR: Shared file container could not be created for app group: \(appGroup)")
            fatalError("Shared file container could not be created.")
        }
        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}
