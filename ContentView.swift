import SwiftUI

struct ContentView: View {
    @EnvironmentObject var doc: DocumentManager

    var body: some View {
        VStack(spacing: 0) {
            // Find & Replace bar
            if doc.showFind {
                FindReplaceBar()
                    .environmentObject(doc)
                Divider()
            }

            // Go to line sheet
            if doc.showGoToLine {
                GoToLineBar()
                    .environmentObject(doc)
                Divider()
            }

            // Main text editor
            NotepadTextView(
                text: $doc.text,
                fontSize: $doc.fontSize,
                wordWrap: $doc.wordWrap,
                isModified: $doc.isModified
            )

            // Status bar
            if doc.showStatusBar {
                Divider()
                StatusBar(text: doc.text)
            }
        }
        .navigationTitle(doc.windowTitle)
        .background(Color(NSColor.textBackgroundColor))
    }
}

// MARK: - Status Bar

struct StatusBar: View {
    let text: String

    private var lineCount: Int {
        text.isEmpty ? 1 : text.components(separatedBy: "\n").count
    }

    private var characterCount: Int {
        text.count
    }

    private var wordCount: Int {
        let words = text.split { $0.isWhitespace || $0.isNewline }
        return words.count
    }

    var body: some View {
        HStack {
            Text("Lines: \(lineCount)")
            Divider().frame(height: 12)
            Text("Words: \(wordCount)")
            Divider().frame(height: 12)
            Text("Characters: \(characterCount)")
            Spacer()
            Text("UTF-8")
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
