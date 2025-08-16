//
//  File.swift
//  SyntaxEditor
//
//  Created by Johannes Bilk on 15.08.25.
//

import Foundation
import AppKit

public protocol InsertionHandler {
    func insertText(_ text: String)
    func replaceText(in range: NSRange, with text: String)
}

struct SyntaxEditorController: InsertionHandler {
    private weak var textView: NSTextView?

    init(textView: NSTextView) {
        self.textView = textView
    }

    func insertText(_ text: String) {
        DispatchQueue.main.async {
            self.textView?.insertText(text, replacementRange: self.textView?.selectedRange ?? NSRange(location: 0, length: 0))
        }
    }
    
    func insertText(_ text: String, at location: Int) {
        DispatchQueue.main.async {
            self.textView?.insertText(text, replacementRange: NSRange(location: location, length: 0))
        }
    }
    
//    func insertText(_ text: String, at whitespace: WhitespaceLocation) {
//        DispatchQueue.main.async {
//            guard let textView = self.textView else { return }
//            let cursorIndex = textView.selectedRange.location
//            
//            let bounds = self.whitespaceBounds(in: textView.string, cursorIndex: cursorIndex)
//            
//            var insertIndex: Int?
//            switch whitespace {
//            case .before:
//                insertIndex = bounds.before.map { $0 + 1 } // after the whitespace
//            case .after:
//                insertIndex = bounds.after ?? textView.string.count
//            case .both:
//                if let before = bounds.before, let after = bounds.after {
//                    // Replace both surrounding whitespaces with `text`
//                    let range = NSRange(location: before + 1, length: after - before - 1)
//                    textView.insertText(text, replacementRange: range)
//                    return
//                }
//            }
//            
//            if let index = insertIndex {
//                textView.insertText(text, replacementRange: NSRange(location: index, length: 0))
//            }
//        }
//    }

    private func whitespaceBounds(in text: String, cursorIndex: Int) -> (before: Int?, after: Int?) {
        let characters = Array(text)
        
        var beforeIndex: Int? = nil
        for i in stride(from: cursorIndex - 1, through: 0, by: -1) {
            if characters[i].isWhitespace {
                beforeIndex = i
                break
            }
        }
        
        var afterIndex: Int? = nil
        for i in stride(from: cursorIndex, to: characters.count, by: 1) {
            if characters[i].isWhitespace {
                afterIndex = i
                break
            }
        }
        
        return (beforeIndex, afterIndex)
    }
    
    func replaceText(in range: NSRange, with text: String) {
        DispatchQueue.main.async {
            self.textView?.replaceCharacters(in: range, with: text)
        }
    }
}

public enum WhitespaceLocation {
    case before, after, both
}
