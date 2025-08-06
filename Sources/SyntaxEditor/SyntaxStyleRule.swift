//
//  SyntaxOption.swift
//  CodeEditor
//
//  Created by Johannes Bilk on 27.07.25.
//

import Foundation
import AppKit

public struct SyntaxStyleRule {
    var pattern: String
    var regex: NSRegularExpression?
    var color: NSColor = .labelColor
    var backgroundColor: NSColor = .clear
    var weight: NSFont.Weight = .regular
    var size: CGFloat = 12
    
    var italic: Bool = false
    var underline: Bool = false
    var strikethrough: Bool = false
    var alignment: TextAlignment = .left
    var paragraphSpacing: [ParagraphSpacing] = []
    var glyphRange: GlyphRange
    var markdownFont: MarkdownFont = .system
    var baseline: TextBaseline = .base
    
    public init(
        glyphs: String,
        color: NSColor = .labelColor,
        backgroundColor: NSColor = .clear,
        font: MarkdownFont = .system,
        size: CGFloat = 12,
        style: [FontStyle] = [],
        alignment: TextAlignment = .left,
        paragraphSpacing: [ParagraphSpacing] = [],
        baseline: TextBaseline = .base,
        glyphRange: GlyphRange = .not
    ) {
        self.pattern = "\(glyphs).*?\(glyphs)"
        self.regex = SyntaxStyleRule.cachedRegex(for: self.pattern)
        self.color = color
        self.backgroundColor = backgroundColor
        self.weight = style.contains(.bold) ? .bold : .regular
        self.size = size
        self.italic = style.contains(.italic) ? true : false
        self.underline = style.contains(.underline) ? true : false
        self.strikethrough = style.contains(.strikethrough) ? true : false
        self.alignment = alignment
        self.paragraphSpacing = paragraphSpacing
        self.glyphRange = glyphRange
        self.markdownFont = font
        self.baseline = baseline
    }
    
    public init(
        glyphs: [String],
        color: NSColor = .labelColor,
        backgroundColor: NSColor = .clear,
        font: MarkdownFont = .system,
        size: CGFloat = 12,
        style: [FontStyle] = [],
        alignment: TextAlignment = .left,
        paragraphSpacing: [ParagraphSpacing] = [],
        baseline: TextBaseline = .base,
        glyphRange: GlyphRange = .not
    ) {
        let escapedGlyphs = glyphs.map { NSRegularExpression.escapedPattern(for: $0) }
        let delimitersPattern = "(" + escapedGlyphs.joined(separator: "|") + ")"

        self.pattern = "\(delimitersPattern)(.+?)\\1" // \1 = same opening and closing
        self.regex = SyntaxStyleRule.cachedRegex(for: self.pattern)
        self.color = color
        self.backgroundColor = backgroundColor
        self.weight = style.contains(.bold) ? .bold : .regular
        self.size = size
        self.italic = style.contains(.italic) ? true : false
        self.underline = style.contains(.underline) ? true : false
        self.strikethrough = style.contains(.strikethrough) ? true : false
        self.alignment = alignment
        self.paragraphSpacing = paragraphSpacing
        self.glyphRange = glyphRange
        self.markdownFont = font
        self.baseline = baseline
    }
    
    public init(
        pattern: String,
        options: NSRegularExpression.Options = [],
        color: NSColor = .labelColor,
        backgroundColor: NSColor = .clear,
        font: MarkdownFont = .system,
        size: CGFloat = 12,
        style: [FontStyle] = [],
        alignment: TextAlignment = .left,
        paragraphSpacing: [ParagraphSpacing] = [],
        baseline: TextBaseline = .base,
        glyphRange: GlyphRange = .not
    ) {
        self.pattern = pattern
        self.regex = SyntaxStyleRule.cachedRegex(for: pattern, options: options)
        self.color = color
        self.backgroundColor = backgroundColor
        self.weight = style.contains(.bold) ? .bold : .regular
        self.size = size
        self.italic = style.contains(.italic) ? true : false
        self.underline = style.contains(.underline) ? true : false
        self.strikethrough = style.contains(.strikethrough) ? true : false
        self.alignment = alignment
        self.paragraphSpacing = paragraphSpacing
        self.glyphRange = glyphRange
        self.markdownFont = font
        self.baseline = baseline
    }

    public static func `default`(baseFontSize: CGFloat = 12) -> [SyntaxStyleRule] {
        var options: [SyntaxStyleRule] = [
            SyntaxStyleRule(pattern: ".*", size: baseFontSize, glyphRange: .not),
            SyntaxStyleRule(
                pattern: "(`){3}((?!\\1).)+\\1{3}",
                options: [.dotMatchesLineSeparators],
                font: .monospace,
                size: baseFontSize,
                glyphRange: .leadingAndTrailing(3, 3)
            ),
            SyntaxStyleRule(
                pattern: "^>.*",
                options: [.anchorsMatchLines],
                font: .quote,
                size: baseFontSize,
                alignment: .right,
                glyphRange: .leadingOnly(1)
            ),
            SyntaxStyleRule(
                pattern: "^(\\t*)[\\-\\*\\•]\\s",
                options: [.anchorsMatchLines],
                size: baseFontSize,
                paragraphSpacing: [.headIndent(4), .spacingBefore(4), .spacingAfter(4)],
                glyphRange: .leadingOnly(1)
            ),
            SyntaxStyleRule(
                pattern: "^(\\t*)\\d+[\\.\\)]\\s",
                options: [.anchorsMatchLines],
                size: baseFontSize,
                paragraphSpacing: [.headIndent(4), .spacingBefore(4), .spacingAfter(4)],
                glyphRange: .leadingOnly(1)
            ),
            SyntaxStyleRule(
                pattern: "^//.*$",
                options: [.anchorsMatchLines],
                color: .gray,
                size: baseFontSize,
                glyphRange: .not
            ),
            SyntaxStyleRule(
                pattern: "\\[\\^(.*?)\\]",
                size: baseFontSize - 3,
                baseline: .raised,
                glyphRange: .leadingAndTrailing(2, 1)
            ),
            SyntaxStyleRule(glyphs: "`", font: .monospace, size: baseFontSize, glyphRange: .leadingAndTrailing(1, 1)),
            SyntaxStyleRule(glyphs: "==", size: baseFontSize, style: [.underline], glyphRange: .leadingAndTrailing(2, 2)),
            SyntaxStyleRule(glyphs: "~~", size: 12, style: [.strikethrough], glyphRange: .leadingAndTrailing(2, 2)),
            SyntaxStyleRule(glyphs: ["_", "*", "/"], size: baseFontSize, style: [.italic], glyphRange: .leadingAndTrailing(1, 1)),
            SyntaxStyleRule(glyphs: ["__", "**", "//"], size: baseFontSize, style: [.bold], glyphRange: .leadingAndTrailing(2, 2)),
            SyntaxStyleRule(glyphs: ["___", "***", "///"], size: baseFontSize, style: [.bold, .italic], glyphRange: .leadingAndTrailing(3, 3)),
        ]
        
        for i in 1...5 {
            options.append(
                SyntaxStyleRule(
                    pattern: "^#{\(i)} \\S.*$",
                    options: [.anchorsMatchLines],
                    size: baseFontSize + 12 - CGFloat(2 * i),
                    style: [.bold],
                    paragraphSpacing: [.lineSpacing(8)],
                    glyphRange: .custom({ match, nsText in
                        let line = nsText.substring(with: match.range)
                        let leadingHashes = line.prefix(while: { $0 == "#" || $0 == " " }).count
                        return [NSRange(location: match.range.location, length: leadingHashes)]
                    })
                )
            )
        }
        
        return options
    }
}

public enum GlyphRange {
    case not
    case leadingAndTrailing(Int, Int)
    case leadingOnly(Int)
    case custom((NSTextCheckingResult, NSString) -> [NSRange])
}

public enum MarkdownFont {
    case system, monospace, quote
    
    func font(ofSize: CGFloat = 12, weight: NSFont.Weight = .regular) -> NSFont {
        switch self {
        case .system: .systemFont(ofSize: ofSize, weight: weight)
        case .monospace: .monospacedSystemFont(ofSize: ofSize, weight: weight)
        case .quote: NSFont(name: "Palatino", size: ofSize) ?? .systemFont(ofSize: ofSize)
        }
    }
}

public enum FontStyle {
    case bold, italic, underline, strikethrough
}

public enum TextAlignment {
    case left, center, right, justified

    var nsTextAlignment: NSTextAlignment {
        switch self {
        case .left: .left
        case .center: .center
        case .right: .right
        case .justified: .justified
        }
    }
}

public enum ParagraphSpacing {
    case lineSpacing(CGFloat)
    case spacingBefore(CGFloat)
    case spacingAfter(CGFloat)
    case headIndent(CGFloat)
    case tailIndent(CGFloat)
    case firstIndent(CGFloat)
}

public enum TextBaseline {
    case base, raised, lowered
}

extension SyntaxStyleRule {
    func hiddenGlyphRanges(in text: String) -> [NSRange] {
        guard let regex = regex else { return [] }
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, options: [], range: fullRange)

        var rangesToGrayOut: [NSRange] = []

        for match in matches {
            switch glyphRange {
            case .not:
                continue
            case .leadingOnly(let count):
                if match.range.length >= 2 * count {
                    rangesToGrayOut.append(NSRange(location: match.range.location, length: count))
                }
            case .leadingAndTrailing(let count, let count2):
                if match.range.length >= 2 * count {
                    rangesToGrayOut.append(NSRange(location: match.range.location, length: count))
                    rangesToGrayOut.append(NSRange(location: match.range.location + match.range.length - count2, length: count2))
                }
            case .custom(let generator):
                rangesToGrayOut.append(contentsOf: generator(match, nsText))
            }
        }

        return rangesToGrayOut
    }
}

private extension SyntaxStyleRule {
    nonisolated(unsafe) static var regexCache = NSCache<NSString, NSRegularExpression>()
    
    static func cachedRegex(for pattern: String, options: NSRegularExpression.Options = []) -> NSRegularExpression? {
        let key = "\(options.rawValue)-\(pattern)" as NSString
        
        if let cached = regexCache.object(forKey: key) {
            return cached
        }
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }
        
        regexCache.setObject(regex, forKey: key)
        return regex
    }
}
