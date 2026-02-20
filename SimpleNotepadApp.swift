import SwiftUI

@main
struct SimpleNotepadApp: App {
    @StateObject private var documentManager = DocumentManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(documentManager)
                .frame(minWidth: 600, minHeight: 400)
        }
        .commands {
            // File menu commands
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    documentManager.newDocument()
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Open…") {
                    documentManager.openDocument()
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("Save") {
                    documentManager.saveDocument()
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As…") {
                    documentManager.saveDocumentAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            // Edit menu - Find & Replace
            CommandGroup(after: .pasteboard) {
                Divider()

                Button("Find…") {
                    documentManager.showFind = true
                    documentManager.showReplace = false
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Find and Replace…") {
                    documentManager.showFind = true
                    documentManager.showReplace = true
                }
                .keyboardShortcut("h", modifiers: .command)

                Button("Go to Line…") {
                    documentManager.showGoToLine = true
                }
                .keyboardShortcut("g", modifiers: .command)
            }

            // Format menu
            CommandMenu("Format") {
                Toggle("Word Wrap", isOn: $documentManager.wordWrap)
                    .keyboardShortcut("w", modifiers: [.command, .shift])

                Divider()

                Menu("Font Size") {
                    Button("Increase") {
                        documentManager.fontSize = min(documentManager.fontSize + 1, 72)
                    }
                    .keyboardShortcut("+", modifiers: .command)

                    Button("Decrease") {
                        documentManager.fontSize = max(documentManager.fontSize - 1, 8)
                    }
                    .keyboardShortcut("-", modifiers: .command)

                    Button("Reset") {
                        documentManager.fontSize = 13
                    }
                    .keyboardShortcut("0", modifiers: .command)
                }

                Toggle("Show Status Bar", isOn: $documentManager.showStatusBar)
            }
        }
    }
}
