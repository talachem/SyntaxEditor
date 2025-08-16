//
//  File.swift
//  SyntaxEditor
//
//  Created by Johannes Bilk on 03.08.25.
//

import Foundation
import AppKit

extension SyntaxEditorCore.Coordinator {
    func applySyntaxStyling(in range: NSRange? = nil) -> Set<LabelWithOffset> {
        guard let textView = self.textView else { return [] }
        
        let selectedRange = textView.selectedRange()
        let nsText = parent.text as NSString
        let fullTextLength = nsText.length
        
        let dirtyRange = range ?? NSRange(location: 0, length: fullTextLength)
        let expanded = expandedRange(around: dirtyRange, in: nsText, paragraphPadding: 2)
        
        let attributedString = NSMutableAttributedString(attributedString: textView.attributedString())
        attributedString.replaceCharacters(in: expanded, with: NSAttributedString(string: nsText.substring(with: expanded))) // Reset to plain
        
        let secondaryColor = NSColor.secondaryLabelColor
        
        var results: Set<LabelWithOffset> = []
        
        for option in parent.theme.syntaxStyleRules {
            guard let regex = option.regex else { continue }
            let matches = regex.matches(in: parent.text, range: expanded)
            
            for match in matches {
                let substring = nsText.substring(with: match.range)
                var attributes: [NSAttributedString.Key: Any] = [
                    .font: font(from: option),
                    .foregroundColor: option.color,
                    .backgroundColor: option.backgroundColor
                ]
                
                if option.underline {
                    attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                }
                
                if option.strikethrough {
                    attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                }
                
                if option.baseline == .raised {
                    attributes[.baselineOffset] = 6
                } else if option.baseline == .lowered {
                    attributes[.baselineOffset] = -3
                }
                
                let paragraphStyle = NSMutableParagraphStyle()
                
                for spacing in option.paragraphSpacing {
                    switch spacing {
                    case .lineSpacing(let value): paragraphStyle.lineSpacing = value
                    case .spacingBefore(let value): paragraphStyle.paragraphSpacingBefore = value
                    case .spacingAfter(let value): paragraphStyle.paragraphSpacing = value
                    case .headIndent(let value): paragraphStyle.headIndent = value
                    case .tailIndent(let value): paragraphStyle.tailIndent = value
                    case .firstIndent(let value): paragraphStyle.firstLineHeadIndent = value
                    }
                }
                paragraphStyle.alignment = option.alignment.nsTextAlignment
                attributes[.paragraphStyle] = paragraphStyle
                
                attributedString.addAttributes(attributes, range: match.range)
                
                if let first = substring.first, parent.triggerCharacters.contains(first),
                   !attributes.isEmpty &&
                    substring.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 &&
                    regex.pattern != ".*"
                {
                    attributedString.addAttributes(attributes, range: match.range)
                    results.insert(LabelWithOffset(label: substring, offset: match.range.location, trigger: String(first)))
                }
            }
            
            let grayoutRanges = option.hiddenGlyphRanges(in: parent.text)
            for range in grayoutRanges where NSIntersectionRange(range, expanded).length > 0 {
                attributedString.addAttribute(.foregroundColor, value: secondaryColor, range: range)
            }
        }
        
        textView.textStorage?.beginEditing()
        textView.textStorage?.replaceCharacters(in: expanded, with: attributedString.attributedSubstring(from: expanded))
        textView.textStorage?.endEditing()
        
        textView.setSelectedRange(selectedRange)
        
        return results
    }
    
    func font(from option: SyntaxStyleRule) -> NSFont {
        let baseFont = option.markdownFont.font(ofSize: option.size, weight: option.weight)
        var traits: NSFontDescriptor.SymbolicTraits = []
        
        if option.italic {
            traits.insert(.italic)
        }
        
        if option.weight == .bold {
            traits.insert(.bold)
        }
        
        let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: option.size) ?? baseFont
    }
    
    private func expandedRange(around range: NSRange, in text: NSString, paragraphPadding: Int = 1) -> NSRange {
        let fullLength = text.length
        let lower = range.location
        let upper = range.upperBound
        
        // Expand to cover full paragraph(s)
        var lowerRange = text.paragraphRange(for: NSRange(location: lower, length: 0))
        var upperRange = text.paragraphRange(for: NSRange(location: upper, length: 0))
        
        // Expand padding paragraphs upwards
        for _ in 0..<paragraphPadding {
            if lowerRange.location == 0 { break }
            let previousParagraphEnd = lowerRange.location - 1
            let previousParagraphRange = text.paragraphRange(for: NSRange(location: previousParagraphEnd, length: 0))
            lowerRange = NSUnionRange(lowerRange, previousParagraphRange)
        }
        
        // Expand padding paragraphs downwards
        for _ in 0..<paragraphPadding {
            let nextParagraphStart = upperRange.upperBound
            if nextParagraphStart >= fullLength { break }
            let nextParagraphRange = text.paragraphRange(for: NSRange(location: nextParagraphStart, length: 0))
            upperRange = NSUnionRange(upperRange, nextParagraphRange)
        }
        
        return NSUnionRange(lowerRange, upperRange)
    }
}

public struct LabelWithOffset: Hashable {
    public var label: String
    public var offset: Int
    public var trigger: String
}
