//
//  ContentView.swift
//  DigitalMemoPad
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddMemo = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var memos: FetchedResults<Item>

    var body: some View {
        NavigationStack {
            Group {
                if memos.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Memos Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Tap the + button to create your first memo")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(memos) { memo in
                            NavigationLink(value: memo) {
                                MemoRow(memo: memo)
                            }
                        }
                        .onDelete(perform: deleteMemos)
                    }
                }
            }
            .navigationTitle("Digital Memo Pad")
            .navigationDestination(for: Item.self) { memo in
                MemoDetailView(memo: memo)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMemo = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                if !memos.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddMemo) {
                AddMemoView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func deleteMemos(offsets: IndexSet) {
        withAnimation {
            offsets.map { memos[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting: \(error)")
            }
        }
    }
}

// MARK: - Memo Row View
struct MemoRow: View {
    let memo: Item
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(memoTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(memoPreview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(memo.timestamp ?? Date(), style: .relative)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
    
    private var memoTitle: String {
        let content = memo.content ?? "Untitled Memo"
        let firstLine = content.components(separatedBy: .newlines).first ?? "Untitled Memo"
        return firstLine.isEmpty ? "Untitled Memo" : firstLine
    }
    
    private var memoPreview: String {
        let content = memo.content ?? ""
        let lines = content.components(separatedBy: .newlines)
        if lines.count > 1 {
            return lines.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "No additional content"
    }
}

// MARK: - Memo Detail View
struct MemoDetailView: View {
    let memo: Item
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var editedContent: String = ""
    
    var body: some View {
        VStack {
            if isEditing {
                TextEditor(text: $editedContent)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(memo.content ?? "Empty Memo")
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Created: \(memo.timestamp ?? Date(), formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Memo" : "Memo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveMemo()
                    } else {
                        editedContent = memo.content ?? ""
                        isEditing = true
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                        editedContent = ""
                    }
                }
            }
        }
    }
    
    private func saveMemo() {
        memo.content = editedContent
        memo.timestamp = Date()
        
        do {
            try viewContext.save()
            isEditing = false
        } catch {
            print("Error saving: \(error)")
        }
    }
}

// MARK: - Add Memo View
struct AddMemoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var memoContent = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $memoContent)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("New Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMemo()
                    }
                    .disabled(memoContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveMemo() {
        let newMemo = Item(context: viewContext)
        newMemo.timestamp = Date()
        newMemo.content = memoContent
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving: \(error)")
        }
    }
}

// MARK: - Date Formatter
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

// MARK: - Preview
#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
