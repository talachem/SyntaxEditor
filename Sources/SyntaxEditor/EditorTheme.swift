//
//  EditorTheme.swift
//  CodeEditor
//
//  Created by Johannes Bilk on 27.07.25.
//

import SwiftUI
import AppKit

public struct EditorTheme: Identifiable, Themable {
    public var id: UUID
    var syntaxStyleRules: [SyntaxStyleRule]
    var backgroundColor: NSColor = .textBackgroundColor
    
    var font: NSFont

    public init(
        id: UUID = UUID(),
        font: NSFont = .systemFont(ofSize: 12, weight: .regular),
        syntaxStyleRules: [SyntaxStyleRule]? = nil,
        backgroundColor: NSColor = .textBackgroundColor
    ) {
        self.id = id
        self.font = font
        self.syntaxStyleRules = syntaxStyleRules ?? SyntaxStyleRule.default(baseFontSize: font.pointSize)
        self.backgroundColor = backgroundColor
    }
    
    public init(
        id: UUID = UUID(),
        fontSize: CGFloat = 12,
        fontWeight: NSFont.Weight = .regular,
        syntaxStyleRules: [SyntaxStyleRule]? = nil,
        backgroundColor: NSColor = .textBackgroundColor
    ) {
        self.id = id
        self.font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        self.syntaxStyleRules = syntaxStyleRules ?? SyntaxStyleRule.default(baseFontSize: font.pointSize)
        self.backgroundColor = backgroundColor
    }
    
    public static func `default`(fontSize: CGFloat = 12) -> EditorTheme {
        .init(syntaxStyleRules: SyntaxStyleRule.default(baseFontSize: fontSize))
    }
}
