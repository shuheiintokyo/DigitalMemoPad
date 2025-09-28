//
//  DigitalMemoPadWidget.swift
//  DigitalMemoPad Widget with Debug Logging
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Widget Entry
struct MemoEntry: TimelineEntry {
    let date: Date
    let memos: [MemoData]
    let debugInfo: DebugInfo
}

// Debug information structure
struct DebugInfo {
    let fetchTime: Date
    let storeURL: String
    let fileExists: Bool
    var totalCount: Int
}

// Simple data structure for widget display
struct MemoData: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let timestamp: Date
    
    var status: MemoStatus {
        let elapsed = Date().timeIntervalSince(timestamp)
        let hours = elapsed / 3600
        
        if hours >= 5 {
            return .alarm
        } else if hours >= 3 {
            return .warning
        } else {
            return .normal
        }
    }
    
    var timeElapsed: String {
        let elapsed = Date().timeIntervalSince(timestamp)
        let hours = Int(elapsed / 3600)
        let minutes = Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m ago"
        } else {
            return "\(minutes)m ago"
        }
    }
}

enum MemoStatus {
    case normal
    case warning
    case alarm
    
    var backgroundColor: Color {
        switch self {
        case .normal:
            return Color(.systemBackground)
        case .warning:
            return Color.yellow.opacity(0.3)
        case .alarm:
            return Color.red.opacity(0.3)
        }
    }
    
    var iconName: String {
        switch self {
        case .normal:
            return "clock"
        case .warning:
            return "exclamationmark.triangle"
        case .alarm:
            return "bell.badge"
        }
    }
}

// MARK: - Core Data Stack for Widget
class WidgetCoreDataStack {
    static let shared = WidgetCoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DigitalMemoPad")
        
        // Use App Group container for shared data
        guard let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.shuhei.digitalmemopad")?.appendingPathComponent("DigitalMemoPad.sqlite") else {
            fatalError("Could not create shared container URL")
        }
        
        print("\n🟣 ========== WIDGET CORE DATA INIT ==========")
        print("📂 Attempting to use store at: \(storeURL.path)")
        
        // Check if file exists
        let fileExists = FileManager.default.fileExists(atPath: storeURL.path)
        print("📁 SQLite file exists: \(fileExists ? "YES ✅" : "NO ❌")")
        
        if fileExists {
            let attributes = try? FileManager.default.attributesOfItem(atPath: storeURL.path)
            let fileSize = attributes?[.size] as? Int64 ?? 0
            print("📏 File size: \(fileSize) bytes")
        }
        
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { storeDesc, error in
            if let error = error {
                print("❌ Widget Core Data error: \(error)")
            } else {
                print("✅ Widget Core Data loaded successfully")
                print("💾 Store URL: \(storeDesc.url?.absoluteString ?? "unknown")")
            }
        }
        print("🟣 ==========================================\n")
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}

// MARK: - Timeline Provider
struct MemoProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> MemoEntry {
        MemoEntry(
            date: Date(),
            memos: [MemoData(title: "Loading...", content: "Memos will appear here", timestamp: Date())],
            debugInfo: DebugInfo(fetchTime: Date(), storeURL: "placeholder", fileExists: false, totalCount: 0)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MemoEntry) -> ()) {
        let (memos, debugInfo) = fetchRecentMemosWithDebug()
        let entry = MemoEntry(date: Date(), memos: memos, debugInfo: debugInfo)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoEntry>) -> ()) {
        let (memos, debugInfo) = fetchRecentMemosWithDebug()
        
        // Create multiple timeline entries for scheduled updates
        var entries: [MemoEntry] = []
        let currentDate = Date()
        
        // Current state
        entries.append(MemoEntry(date: currentDate, memos: memos, debugInfo: debugInfo))
        
        // Schedule future updates based on memo ages
        if let oldestMemo = memos.first {
            let memoAge = currentDate.timeIntervalSince(oldestMemo.timestamp)
            let hoursOld = memoAge / 3600
            
            // Schedule update when memo hits 3 hours (warning)
            if hoursOld < 3 {
                let warningTime = oldestMemo.timestamp.addingTimeInterval(3 * 3600)
                entries.append(MemoEntry(date: warningTime, memos: memos, debugInfo: debugInfo))
                print("📅 Scheduled widget update for warning at: \(warningTime)")
            }
            
            // Schedule update when memo hits 5 hours (alarm)
            if hoursOld < 5 {
                let alarmTime = oldestMemo.timestamp.addingTimeInterval(5 * 3600)
                entries.append(MemoEntry(date: alarmTime, memos: memos, debugInfo: debugInfo))
                print("📅 Scheduled widget update for alarm at: \(alarmTime)")
            }
        }
        
        // If we have scheduled entries, use .atEnd policy to refresh after last entry
        // Otherwise refresh every hour to check memo status
        let policy: TimelineReloadPolicy
        if entries.count > 1 {
            policy = .atEnd  // Refresh after last scheduled entry
        } else {
            // Refresh in 1 hour to check status
            let nextHour = currentDate.addingTimeInterval(3600)
            policy = .after(nextHour)
        }
        
        let timeline = Timeline(entries: entries, policy: policy)
        completion(timeline)
    }
    
    private func fetchRecentMemosWithDebug() -> ([MemoData], DebugInfo) {
        print("\n🟡 ========== WIDGET FETCH DEBUG ==========")
        print("⏰ Fetch initiated at: \(Date())")
        
        let context = WidgetCoreDataStack.shared.viewContext
        var debugInfo = DebugInfo(fetchTime: Date(), storeURL: "", fileExists: false, totalCount: 0)
        
        do {
            // Get store URL for debug
            if let storeURL = context.persistentStoreCoordinator?.persistentStores.first?.url {
                debugInfo = DebugInfo(
                    fetchTime: Date(),
                    storeURL: storeURL.absoluteString,
                    fileExists: FileManager.default.fileExists(atPath: storeURL.path),
                    totalCount: 0
                )
                print("📁 Reading from: \(storeURL.path)")
                print("📁 File exists: \(debugInfo.fileExists ? "YES ✅" : "NO ❌")")
            }
            
            // Manual fetch request using entity name
            let request = NSFetchRequest<NSManagedObject>(entityName: "Item")
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            request.fetchLimit = 5
            
            let items = try context.fetch(request)
            
            // Get total count for debugging
            let countRequest = NSFetchRequest<NSManagedObject>(entityName: "Item")
            let totalCount = try context.count(for: countRequest)
            
            print("📊 Total memos in database: \(totalCount)")
            print("📋 Fetched \(items.count) memos for display")
            
            // List fetched memos
            if items.count > 0 {
                print("📝 Fetched memos:")
                for (index, item) in items.enumerated() {
                    let content = item.value(forKey: "content") as? String ?? "Empty"
                    let preview = content.components(separatedBy: .newlines).first ?? "Empty"
                    print("   \(index + 1). \(preview.prefix(50))...")
                }
            } else {
                print("⚠️ No memos found in database")
            }
            
            print("🟡 ==========================================\n")
            
            let memoData = items.map { item in
                let content = item.value(forKey: "content") as? String ?? "Untitled Memo"
                let timestamp = item.value(forKey: "timestamp") as? Date ?? Date()
                let title = content.components(separatedBy: .newlines).first ?? "Untitled Memo"
                
                return MemoData(
                    title: title.isEmpty ? "Untitled Memo" : title,
                    content: content,
                    timestamp: timestamp
                )
            }
            
            var updatedDebugInfo = debugInfo
            updatedDebugInfo.totalCount = totalCount
            
            return (memoData, updatedDebugInfo)
            
        } catch {
            print("❌ Error fetching memos for widget: \(error)")
            print("🟡 ==========================================\n")
            return ([], debugInfo)
        }
    }
    
    private func fetchRecentMemos() -> [MemoData] {
        let (memos, _) = fetchRecentMemosWithDebug()
        return memos
    }
}

// MARK: - Widget Views
struct MemoWidgetSmallView: View {
    let entry: MemoEntry
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            VStack(spacing: 4) {
                Text("\(entry.memos.count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(entry.memos.count == 1 ? "memo" : "memos")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Debug info in small text
                Text("DB: \(entry.debugInfo.totalCount)")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            
            Text("Digital Memo Pad")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct MemoWidgetMediumView: View {
    let entry: MemoEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Digital Memo Pad")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(entry.memos.count)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(entry.memos.count == 1 ? "memo stored" : "memos stored")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Show status of most recent memo
                    if let firstMemo = entry.memos.first {
                        HStack {
                            Image(systemName: firstMemo.status.iconName)
                                .foregroundColor(firstMemo.status == .alarm ? .red : firstMemo.status == .warning ? .orange : .blue)
                            Text(firstMemo.timeElapsed)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Debug footer
            HStack {
                Text("DB Total: \(entry.debugInfo.totalCount) | File: \(entry.debugInfo.fileExists ? "✅" : "❌")")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Spacer()
                Text("Updated: \(entry.debugInfo.fetchTime, formatter: timeFormatter)")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(entry.memos.first?.status.backgroundColor ?? Color(.systemBackground))
    }
    
    private func timeAgo(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct MemoWidgetLargeView: View {
    let entry: MemoEntry
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Digital Memo Pad")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Text("\(entry.memos.count)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                Text(entry.memos.count == 1 ? "memo stored" : "memos stored")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                if entry.memos.count > 0 {
                    Divider()
                        .frame(width: 100)
                    
                    VStack(spacing: 4) {
                        Text("Last activity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(timeAgo(for: entry.memos.first?.timestamp ?? Date()))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("Tap + to create your first memo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            
            Spacer()
            
            // Debug footer
            VStack(spacing: 2) {
                Text("Debug Info")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                Text("Database Total: \(entry.debugInfo.totalCount) memos")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Text("File: \(entry.debugInfo.fileExists ? "✅ Exists" : "❌ Not Found")")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Text("Updated: \(entry.debugInfo.fetchTime, formatter: timeFormatter)")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
    
    private func timeAgo(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Time formatter for debug display
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    return formatter
}()

// MARK: - Widget Configuration
struct MemoWidgetEntryView: View {
    var entry: MemoProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            MemoWidgetSmallView(entry: entry)
        case .systemMedium:
            MemoWidgetMediumView(entry: entry)
        case .systemLarge:
            MemoWidgetLargeView(entry: entry)
        default:
            MemoWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Definition
@main
struct DigitalMemoPadWidget: Widget {
    let kind: String = "DigitalMemoPadWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MemoProvider()) { entry in
            if #available(iOS 17.0, *) {
                MemoWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MemoWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Digital Memo Pad")
        .description("View your recent memos at a glance with real-time updates.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
