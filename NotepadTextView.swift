import SwiftUI
import AppKit

struct NotepadTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var fontSize: CGFloat
    @Binding var wordWrap: Bool
    @Binding var isModified: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()

        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = !wordWrap
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.textBackgroundColor

        // Configure text view
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.drawsBackground = true
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.textColor
        textView.insertionPointColor = NSColor.textColor

        // Font
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

        // Text container & layout
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = !wordWrap

        configureWrapping(textView: textView, scrollView: scrollView, wrap: wordWrap)

        // Set initial text
        textView.string = text

        // Set delegate
        textView.delegate = context.coordinator
        context.coordinator.textView = textView
        context.coordinator.startObserving()

        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update text only if it actually changed (avoids cursor jumping)
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }

        // Update font size
        let newFont = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        if textView.font != newFont {
            textView.font = newFont
        }

        // Update word wrap
        configureWrapping(textView: textView, scrollView: scrollView, wrap: wordWrap)
    }

    private func configureWrapping(textView: NSTextView, scrollView: NSScrollView, wrap: Bool) {
        if wrap {
            textView.isHorizontallyResizable = false
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(
                width: scrollView.contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            scrollView.hasHorizontalScroller = false
        } else {
            textView.isHorizontallyResizable = true
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            scrollView.hasHorizontalScroller = true
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NotepadTextView
        weak var textView: NSTextView?

        init(_ parent: NotepadTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            parent.isModified = true
        }

        func startObserving() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleFindHighlight(_:)),
                name: .findHighlight,
                object: nil
            )
        }

        @objc func handleFindHighlight(_ notification: Notification) {
            guard let textView = textView,
                  let range = notification.userInfo?["range"] as? NSRange else { return }
            textView.setSelectedRange(range)
            textView.scrollRangeToVisible(range)
            textView.showFindIndicator(for: range)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
