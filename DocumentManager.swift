import SwiftUI
import AppKit

class DocumentManager: ObservableObject {
    @Published var text: String = ""
    @Published var currentFileURL: URL? = nil
    @Published var isModified: Bool = false
    @Published var wordWrap: Bool = true
    @Published var fontSize: CGFloat = 13
    @Published var showFind: Bool = false
    @Published var showReplace: Bool = false
    @Published var showGoToLine: Bool = false
    @Published var showStatusBar: Bool = true

    var windowTitle: String {
        let filename = currentFileURL?.lastPathComponent ?? "Untitled"
        let modified = isModified ? " — Edited" : ""
        return "\(filename)\(modified) — SimpleNotepad"
    }

    // MARK: - File Operations

    func newDocument() {
        if isModified {
            let proceed = promptToSave()
            if !proceed { return }
        }
        text = ""
        currentFileURL = nil
        isModified = false
    }

    func openDocument() {
        if isModified {
            let proceed = promptToSave()
            if !proceed { return }
        }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .utf8PlainText]
        panel.allowsOtherFileTypes = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                text = try String(contentsOf: url, encoding: .utf8)
                currentFileURL = url
                isModified = false
            } catch {
                showError("Could not open file: \(error.localizedDescription)")
            }
        }
    }

    func saveDocument() {
        if let url = currentFileURL {
            writeFile(to: url)
        } else {
            saveDocumentAs()
        }
    }

    func saveDocumentAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = currentFileURL?.lastPathComponent ?? "Untitled.txt"

        if panel.runModal() == .OK, let url = panel.url {
            writeFile(to: url)
            currentFileURL = url
        }
    }

    // MARK: - Helpers

    private func writeFile(to url: URL) {
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            currentFileURL = url
            isModified = false
        } catch {
            showError("Could not save file: \(error.localizedDescription)")
        }
    }

    private func promptToSave() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Do you want to save changes?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            saveDocument()
            return true
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.runModal()
    }
}
