//
//  SwiftUIView.swift
//  SyntaxEditor
//
//  Created by Johannes Bilk on 30.07.25.
//

import SwiftUI

public struct SyntaxViewer: View {
    public let text: String
    public let theme: EditorTheme
    public var padding: CGFloat? = nil
    public var ignoreFontSize: Bool = false
    
    private var baseFontSize: CGFloat {
        theme.font.pointSize
    }
    
    public init(
        text: String,
        theme: EditorTheme = .default(),
        padding: CGFloat? = nil,
        ignoreFontSize: Bool = false
    ) {
        self.text = text
        self.theme = theme
        self.padding = padding
        self.ignoreFontSize = ignoreFontSize
    }
    
    public var body: some View {
        Text(attributedString(from: text, rules: theme.syntaxStyleRules))
    }
    
    func attributedString(from markdown: String, rules: [SyntaxStyleRule]) -> AttributedString {
        var result = AttributedString(markdown)
        let nsText = markdown as NSString
        
        for rule in rules {
            guard let regex = rule.regex else { continue }
            let matches = regex.matches(in: markdown, range: NSRange(location: 0, length: nsText.length))
            
            for match in matches {
                let fullRange = match.range
                guard let swiftRange = Range(fullRange, in: markdown) else { continue }

                let attributedRange = result.range(of: String(markdown[swiftRange]))
                guard let fullAttrRange = attributedRange else { continue }

                // Apply main style to full match
                let fontSize = ignoreFontSize ? baseFontSize : rule.size
                result[fullAttrRange].font = Font(rule.markdownFont.font(ofSize: fontSize, weight: rule.weight))
                result[fullAttrRange].foregroundColor = Color(nsColor: rule.color)

                if rule.italic {
                    result[fullAttrRange].font = result[fullAttrRange].font?.italic()
                }
                if rule.underline {
                    result[fullAttrRange].underlineStyle = .single
                }
                if rule.strikethrough {
                    result[fullAttrRange].strikethroughStyle = .single
                }

                // Apply gray to leading/trailing glyphs
                let glyphRanges = rule.hiddenGlyphRanges(in: markdown)
                for nsRange in glyphRanges where NSIntersectionRange(nsRange, fullRange).length > 0 {
                    guard let glyphSwiftRange = Range(nsRange, in: markdown),
                          let attrGlyphRange = result.range(of: String(markdown[glyphSwiftRange])) else { continue }

                    result[attrGlyphRange].foregroundColor = .gray // or any muted color
                }
            }
        }

        return result
    }
}
