//
//  DigitalMemoPadWidget.swift
//  DigitalMemoPad Widget with Real-time Core Data
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Widget Entry
struct MemoEntry: TimelineEntry {
    let date: Date
    let memos: [MemoData]
}

// Simple data structure for widget display
struct MemoData: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let timestamp: Date
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
        
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Widget Core Data error: \(error)")
            }
        }
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}

// MARK: - Timeline Provider
struct MemoProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> MemoEntry {
        MemoEntry(date: Date(), memos: [
            MemoData(title: "Loading...", content: "Memos will appear here", timestamp: Date())
        ])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MemoEntry) -> ()) {
        let memos = fetchRecentMemos()
        let entry = MemoEntry(date: Date(), memos: memos)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoEntry>) -> ()) {
        let memos = fetchRecentMemos()
        let entry = MemoEntry(date: Date(), memos: memos)
        
        // Update every 15 minutes for real-time data
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func fetchRecentMemos() -> [MemoData] {
        do {
            let context = WidgetCoreDataStack.shared.viewContext
            
            // Manual fetch request using entity name to avoid class conflicts
            let request = NSFetchRequest<NSManagedObject>(entityName: "Item")
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            request.fetchLimit = 5
            
            let items = try context.fetch(request)
            
            return items.map { item in
                let content = item.value(forKey: "content") as? String ?? "Untitled Memo"
                let timestamp = item.value(forKey: "timestamp") as? Date ?? Date()
                let title = content.components(separatedBy: .newlines).first ?? "Untitled Memo"
                
                return MemoData(
                    title: title.isEmpty ? "Untitled Memo" : title,
                    content: content,
                    timestamp: timestamp
                )
            }
        } catch {
            print("Error fetching memos for widget: \(error)")
            // Return empty state for errors
            return []
        }
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
                
                if entry.memos.count > 0 {
                    Text("Last updated \(timeAgo(for: entry.memos.first?.timestamp ?? Date()))")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
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
        }
        .padding()
    }
    
    private func timeAgo(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

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
