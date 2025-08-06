//
//  File.swift
//  SyntaxEditor
//
//  Created by Johannes Bilk on 05.08.25.
//

import Foundation
import AppKit

extension SyntaxEditorCore.Coordinator {
    func handleTableRebalancing(in textView: NSTextView, range: NSRange) -> Bool {
        let lines = textView.string.components(separatedBy: .newlines)
        let cursorLineIndex = textView.string[..<textView.string.index(textView.string.startIndex, offsetBy: range.location)].components(separatedBy: "\n").count - 1

        // Step 1: Walk up and down to find full table block
        var startLine = cursorLineIndex
        while startLine > 0 && lines[startLine].contains("|") {
            startLine -= 1
        }
        if !lines[startLine].contains("|") { startLine += 1 }

        var endLine = cursorLineIndex
        while endLine < lines.count && lines[endLine].contains("|") {
            endLine += 1
        }

        let tableLines = Array(lines[startLine..<endLine])
        guard tableLines.count >= 2 else { return false }

        // Step 2: Parse into rows of cells
        var rows = tableLines.map { line -> [String] in
            line
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
                .components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }

        // Step 3: Find alignments from divider row (2nd row)
        let alignmentRow = rows[1]
        var alignments: [NSTextAlignment] = alignmentRow.map { cell in
            let hasLeftColon = cell.hasPrefix(":")
            let hasRightColon = cell.hasSuffix(":")
            switch (hasLeftColon, hasRightColon) {
            case (true, true): return .center
            case (false, true): return .right
            default: return .left
            }
        }

        // Step 4: Determine max width per column
        let columnCount = rows.map { $0.count }.max() ?? 0
        var columnWidths = [Int](repeating: 0, count: columnCount)

        for row in rows {
            for (i, cell) in row.enumerated() {
                columnWidths[i] = max(columnWidths[i], cell.count)
            }
        }

        // Step 5: Pad cells
        func padded(_ text: String, to width: Int, alignment: NSTextAlignment) -> String {
            let padding = width - text.count
            guard padding > 0 else { return text }

            switch alignment {
            case .right:
                return String(repeating: " ", count: padding) + text
            case .center:
                let left = padding / 2
                let right = padding - left
                return String(repeating: " ", count: left) + text + String(repeating: " ", count: right)
            default:
                return text + String(repeating: " ", count: padding)
            }
        }

        var rebuiltLines: [String] = []
        for (rowIndex, row) in rows.enumerated() {
            var paddedCells: [String] = []
            for i in 0..<columnCount {
                let cellText = i < row.count ? row[i] : ""
                let alignment = rowIndex == 1 ? .left : (i < alignments.count ? alignments[i] : .left)
                let content = rowIndex == 1
                    ? String(repeating: alignment == .center ? ":" : "-", count: columnWidths[i])
                        + (alignment == .right || alignment == .center ? ":" : "")
                        + (alignment == .left || alignment == .center ? ":" : "")
                    : padded(cellText, to: columnWidths[i], alignment: i < alignments.count ? alignments[i] : .left)
                paddedCells.append(content)
            }
            rebuiltLines.append("| " + paddedCells.joined(separator: " | ") + " |")
        }

        let newTable = rebuiltLines.joined(separator: "\n")

        // Step 6: Replace table in text
        let nsText = textView.string as NSString
        let lineRanges = (0..<lines.count).map { lineIndex -> NSRange in
            let start = lines[..<lineIndex].joined(separator: "\n").count + (lineIndex > 0 ? 1 : 0)
            let length = lines[lineIndex].count
            return NSRange(location: start, length: length)
        }

        guard let startRange = lineRanges[safe: startLine],
              let endRange = lineRanges[safe: endLine - 1] else {
            return false
        }

        let fullRange = NSRange(location: startRange.location, length: endRange.upperBound - startRange.location)
        textView.replaceCharacters(in: fullRange, with: newTable)

        // Update model text
        DispatchQueue.main.async { self.parent.text = textView.string }

        return true
    }
}
