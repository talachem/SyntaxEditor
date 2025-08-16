//
//  SyntaxEditor.swift
//  CodeEditor
//
//  Created by Johannes Bilk on 28.07.25.
//

import SwiftUI

public struct SyntaxEditor: View {
    @Binding public var text: String
    @Binding private var searchQuery: String?
    public let theme: EditorTheme
    public let padding: CGFloat?

    @State private var calculatedHeight: CGFloat = 150
    private var onTextChange: TextChange? = nil
    private var onParagraphChange: TextChange? = nil
    private var onPaste: TextChange? = nil
    private var onSelectionChange: SelectionChange? = nil
    private var stylingResults: StylingResults? = nil
    private var insertionHandler: Insertion? = nil
    
    var triggerCharacters: Set<Character> = ["#", "@", "&", "!", "["]

    public init(
        text: Binding<String>,
        searchQuery: Binding<String?> = .constant(""),
        theme: EditorTheme = .default(),
        padding: CGFloat? = nil,
        triggerCharacters: Set<Character> = ["#", "@", "&", "!", "["]
    ) {
        self._text = text
        self._searchQuery = searchQuery
        self.theme = theme
        self.padding = padding
        self.triggerCharacters = triggerCharacters
    }
    
    public init(
        text: Binding<String>,
        searchQuery: Binding<String?> = .constant(""),
        syntaxStyleRules: [SyntaxStyleRule],
        padding: CGFloat? = nil,
        triggerCharacters: Set<Character> = ["#", "@", "&", "!", "["]
    ) {
        self._text = text
        self._searchQuery = searchQuery
        self.theme = EditorTheme(syntaxStyleRules: syntaxStyleRules)
        self.padding = padding
        self.triggerCharacters = triggerCharacters
    }
    
    public init(
        text: Binding<String>,
        searchQuery: Binding<String?> = .constant(""),
        font: NSFont,
        backgroundColor: NSColor,
        syntaxStyleRules: [SyntaxStyleRule] = SyntaxStyleRule.default(),
        padding: CGFloat? = nil,
        triggerCharacters: Set<Character> = ["#", "@", "&", "!", "["]
    ) {
        self._text = text
        self._searchQuery = searchQuery
        self.theme = EditorTheme(font: font, backgroundColor: backgroundColor)
        self.padding = padding
        self.triggerCharacters = triggerCharacters
    }
    
    public var body: some View {
        SyntaxEditorCore(
            text: $text,
            searchQuery: $searchQuery,
            calculatedHeight: $calculatedHeight,
            theme: theme,
            onTextChange: onTextChange,
            onParagraphChange: onParagraphChange,
            onPaste: onPaste,
            onSelectionChange: onSelectionChange,
            stylingResults: stylingResults,
            insertionHandler: insertionHandler,
            triggerCharacters: triggerCharacters
        )
        .frame(height: calculatedHeight)
    }
    
    public func onTextChange(_ handler: @escaping TextChange) -> SyntaxEditor {
        var copy = self
        copy.onTextChange = handler
        return copy
    }
    
    public func onParagraphChange(_ handler: @escaping TextChange) -> SyntaxEditor {
        var copy = self
        copy.onParagraphChange = handler
        return copy
    }
    
    public func onPaste(_ handler: @escaping TextChange) -> SyntaxEditor {
        var copy = self
        copy.onPaste = handler
        return copy
    }
    
    public func onSelectionChange(_ handler: @escaping SelectionChange) -> SyntaxEditor {
        var copy = self
        copy.onSelectionChange = handler
        return copy
    }
    
    public func stylingResults(_ handler: @escaping StylingResults) -> SyntaxEditor {
        var copy = self
        copy.stylingResults = handler
        return copy
    }
    
    public func insertion(_ handler: @escaping Insertion) -> SyntaxEditor {
        var copy = self
        copy.insertionHandler = handler
        return copy
    }
}
