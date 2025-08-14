//
//  Coordinator.swift
//  SyntaxEditor
//
//  Created by Johannes Bilk on 03.08.25.
//
import Foundation
import AppKit

extension SyntaxEditorCore {
    @MainActor
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxEditorCore
        var textView: NSTextView?
        var selectedRanges: [NSValue] = []
        
        private var lastPasteboardString: String?
        
        init(_ parent: SyntaxEditorCore) {
            self.parent = parent
            self.textView = NSTextView()
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString: String?) -> Bool {
            guard let replacement = replacementString, replacement.count == 1 else {
                return true
            }
            
            if replacement == "\n", handleListContinuation(in: textView, range: range) {
                return false
            }
            
//            if handleTableRebalancing(in: textView, range: range) {
//                return true // <- we already inserted newline within rebalanced table
//            }
            
            if handleCharacterPairWrapping(in: textView, range: range, replacement: replacement) {
                return false
            }
            
            return true
        }
        
        private func handleListContinuation(in textView: NSTextView, range: NSRange) -> Bool {
            let nsText = textView.string as NSString
            let paragraphRange = nsText.paragraphRange(for: range)
            let currentLine = nsText.substring(with: paragraphRange)
            let trimmed = currentLine.trimmingCharacters(in: .whitespaces)

            let unorderedPrefixes = ["- ", "* ", "+ "]
            let orderedPrefixRegex = #"^(\d+)[.)]\s"#

            if let prefix = unorderedPrefixes.first(where: { trimmed.hasPrefix($0) }) {
                let indent = currentLine.prefix(while: \.isWhitespace)
                let continuation = "\n\(indent)\(prefix)"
                
                if trimmed == prefix.trimmingCharacters(in: .whitespaces) {
                    // Exit list if only marker
                    textView.insertText("\n", replacementRange: range)
                } else {
                    textView.insertText(continuation, replacementRange: range)
                }

                DispatchQueue.main.async { self.parent.text = textView.string }
                return true
            }

            if let match = try? NSRegularExpression(pattern: orderedPrefixRegex)
                .firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) {
                
                let numberRange = match.range(at: 1)
                let numberString = (trimmed as NSString).substring(with: numberRange)
                
                if let number = Int(numberString) {
                    let nextNumber = number + 1
                    let indent = currentLine.prefix(while: \.isWhitespace)
                    let continuation = "\n\(indent)\(nextNumber). "
                    
                    textView.insertText(continuation, replacementRange: range)
                    DispatchQueue.main.async { self.parent.text = textView.string }
                    return true
                }
            }

            return false
        }
        
        private func handleCharacterPairWrapping(in textView: NSTextView, range: NSRange, replacement: String) -> Bool {
            let pairs: [Character: Character] = [
                "(": ")", "[": "]", "{": "}", "\"": "\"", "'": "'", "*": "*", "_": "_", "`": "`", "~": "~", "=": "="
            ]
            
            guard let openChar = replacement.first,
                  let closeChar = pairs[openChar],
                  range.length > 0 else {
                return false
            }
            
            let selectedText = (textView.string as NSString).substring(with: range)
            let wrapped = "\(openChar)\(selectedText)\(closeChar)"
            textView.insertText(wrapped, replacementRange: range)
            
            DispatchQueue.main.async {
                self.parent.text = textView.string
            }

            return true
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            var pasted = false
            var pastedString: String?

            if let pasteboardString = NSPasteboard.general.string(forType: .string),
               pasteboardString != lastPasteboardString,
               textView.string.contains(pasteboardString) {

                lastPasteboardString = pasteboardString
                pastedString = pasteboardString
                self.parent.onPaste?(pasteboardString)
                pasted = true
            }

            let fullText = textView.string
            self.parent.text = fullText

            if let selectedRange = textView.selectedRanges.first?.rangeValue {
                if pasted, let pastedString = pastedString {
                    let start = max(selectedRange.location - pastedString.count, 0)
                    let pasteRange = NSRange(location: start, length: pastedString.count)
                    let paragraphRange = (fullText as NSString).paragraphRange(for: pasteRange)

                    let results = applySyntaxStyling(in: paragraphRange)
                    parent.stylingResults?(results)

                } else {
                    let paragraphRange = (fullText as NSString).paragraphRange(for: selectedRange)
                    let paragraph = (fullText as NSString).substring(with: paragraphRange)

                    self.parent.onParagraphChange?(paragraph)
                    self.parent.onTextChange?(fullText)

                    let results = applySyntaxStyling(in: paragraphRange)
                    parent.stylingResults?(results)
                }
            }
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  let onSelectionChange = parent.onSelectionChange,
                  let ranges = textView.selectedRanges as? [NSRange]
            else { return }
            selectedRanges = textView.selectedRanges
            DispatchQueue.main.async {
                onSelectionChange(ranges)
            }
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
