import SwiftUI
import AppKit

struct FindReplaceBar: View {
    @EnvironmentObject var doc: DocumentManager
    @State private var searchText: String = ""
    @State private var replaceText: String = ""
    @State private var caseSensitive: Bool = false
    @State private var matchCount: Int = 0
    @State private var currentMatch: Int = 0

    var body: some View {
        VStack(spacing: 6) {
            // Find row
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                TextField("Find", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                    .onSubmit { findNext() }
                    .onChange(of: searchText) { _ in updateMatchCount() }

                Toggle("Aa", isOn: $caseSensitive)
                    .toggleStyle(.button)
                    .controlSize(.small)
                    .help("Case Sensitive")
                    .onChange(of: caseSensitive) { _ in updateMatchCount() }

                Text(matchCount > 0 ? "\(currentMatch)/\(matchCount)" : "No results")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 70)

                Button(action: findPrevious) {
                    Image(systemName: "chevron.up")
                }
                .controlSize(.small)
                .disabled(matchCount == 0)

                Button(action: findNext) {
                    Image(systemName: "chevron.down")
                }
                .controlSize(.small)
                .disabled(matchCount == 0)

                Spacer()

                Button(action: close) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            // Replace row
            if doc.showReplace {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.2.squarepath")
                        .foregroundColor(.secondary)
                        .frame(width: 16)

                    TextField("Replace", text: $replaceText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                        .onSubmit { replaceCurrent() }

                    Button("Replace") { replaceCurrent() }
                        .controlSize(.small)
                        .disabled(matchCount == 0)

                    Button("Replace All") { replaceAll() }
                        .controlSize(.small)
                        .disabled(matchCount == 0)

                    Spacer()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Search Logic

    private func ranges() -> [Range<String.Index>] {
        var results: [Range<String.Index>] = []
        let source = doc.text
        let query = searchText

        guard !query.isEmpty else { return [] }

        let options: String.CompareOptions = caseSensitive ? [] : .caseInsensitive
        var searchRange = source.startIndex..<source.endIndex

        while let found = source.range(of: query, options: options, range: searchRange) {
            results.append(found)
            searchRange = found.upperBound..<source.endIndex
        }
        return results
    }

    private func updateMatchCount() {
        let r = ranges()
        matchCount = r.count
        currentMatch = r.isEmpty ? 0 : min(currentMatch, r.count)
        if currentMatch == 0 && !r.isEmpty { currentMatch = 1 }
    }

    private func findNext() {
        let r = ranges()
        guard !r.isEmpty else { return }
        currentMatch = currentMatch < r.count ? currentMatch + 1 : 1
        highlightMatch(r[currentMatch - 1])
    }

    private func findPrevious() {
        let r = ranges()
        guard !r.isEmpty else { return }
        currentMatch = currentMatch > 1 ? currentMatch - 1 : r.count
        highlightMatch(r[currentMatch - 1])
    }

    private func highlightMatch(_ range: Range<String.Index>) {
        // Post a notification so the text view can scroll to and select the match
        let nsRange = NSRange(range, in: doc.text)
        NotificationCenter.default.post(
            name: .findHighlight,
            object: nil,
            userInfo: ["range": nsRange]
        )
    }

    private func replaceCurrent() {
        let r = ranges()
        guard !r.isEmpty, currentMatch > 0, currentMatch <= r.count else { return }
        let range = r[currentMatch - 1]
        doc.text.replaceSubrange(range, with: replaceText)
        doc.isModified = true
        updateMatchCount()
    }

    private func replaceAll() {
        let options: String.CompareOptions = caseSensitive ? [] : .caseInsensitive
        let newText = doc.text.replacingOccurrences(
            of: searchText,
            with: replaceText,
            options: options
        )
        if newText != doc.text {
            doc.text = newText
            doc.isModified = true
        }
        updateMatchCount()
    }

    private func close() {
        doc.showFind = false
        doc.showReplace = false
    }
}

// MARK: - Go to Line Bar

struct GoToLineBar: View {
    @EnvironmentObject var doc: DocumentManager
    @State private var lineNumberText: String = ""

    private var totalLines: Int {
        doc.text.isEmpty ? 1 : doc.text.components(separatedBy: "\n").count
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("Go to Line:")
                .foregroundColor(.secondary)

            TextField("Line number", text: $lineNumberText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .onSubmit { goToLine() }

            Text("/ \(totalLines)")
                .foregroundColor(.secondary)
                .font(.system(size: 11))

            Button("Go") { goToLine() }
                .controlSize(.small)

            Spacer()

            Button(action: { doc.showGoToLine = false }) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func goToLine() {
        guard let lineNumber = Int(lineNumberText), lineNumber > 0 else { return }
        let lines = doc.text.components(separatedBy: "\n")
        let targetLine = min(lineNumber, lines.count) - 1

        var charIndex = 0
        for i in 0..<targetLine {
            charIndex += lines[i].count + 1 // +1 for newline
        }

        let nsRange = NSRange(location: charIndex, length: lines[targetLine].count)
        NotificationCenter.default.post(
            name: .findHighlight,
            object: nil,
            userInfo: ["range": nsRange]
        )

        doc.showGoToLine = false
    }
}

// MARK: - Notification for highlighting

extension Notification.Name {
    static let findHighlight = Notification.Name("findHighlight")
}
