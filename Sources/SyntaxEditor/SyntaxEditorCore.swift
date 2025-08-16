//
//  CodeEditor.swift
//  CodeEditor
//
//  Created by Johannes Bilk on 27.07.25.
//

import SwiftUI
import AppKit

public typealias TextChange = (String) -> Void
public typealias SelectionChange = ([NSRange]) -> Void
public typealias StylingResults = (Set<LabelWithOffset>) -> Void
public typealias Insertion = (InsertionHandler) -> Void

struct SyntaxEditorCore: NSViewRepresentable {
    @Binding var text: String
    @Binding var searchQuery: String?
    @Binding var calculatedHeight: CGFloat
    
    var theme: EditorTheme = .default()
    
    var onTextChange: TextChange? = nil
    var onParagraphChange: TextChange? = nil
    var onPaste: TextChange? = nil
    var onSelectionChange: SelectionChange? = nil
    var stylingResults: StylingResults? = nil
    var insertionHandler: Insertion? = nil
    
    var triggerCharacters: Set<Character> = ["#", "@", "&", "!", "["]
    
    func makeNSView(context: Context) -> NSView {
        let view = NSTextView.scrollableTextView()
        guard let textView = view.documentView as? NSTextView else { return view }
        
        context.coordinator.textView = textView
        configureTextView(textView, with: context)
        
        textView.string = self.text
        textView.delegate = context.coordinator
        context.coordinator.applySyntaxStyling()
        
        DispatchQueue.main.async {
            let controller = SyntaxEditorController(textView: textView)
            insertionHandler?(controller)
        }
        
        view.hasVerticalScroller = false
        view.verticalScrollElasticity = .none
        view.autohidesScrollers = true
        view.hasHorizontalScroller = false
        view.horizontalScrollElasticity = .none
        view.borderType = .noBorder
        view.drawsBackground = false
        
        view.contentInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
        view.automaticallyAdjustsContentInsets = false
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(selectedRange)
        }

        let containerSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.size = containerSize

        if let layoutManager = textView.layoutManager,
           let textContainer = textView.textContainer {
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            let height = ceil(boundingRect.height)
            DispatchQueue.main.async {
                self.calculatedHeight = height + 15 // or your preferred padding
            }
        }
        
        context.coordinator.updateSearchHighlights(for: searchQuery)
    }
        
    func configureTextView(_ textView: NSTextView, with context: Context) {
        textView.font = theme.font
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.backgroundColor = theme.backgroundColor
        textView.allowsUndo = true
        
        textView.importsGraphics = false // Stops drag-and-drop image auto-inserts
        
        textView.isAutomaticTextReplacementEnabled = false // disables things like (c) -> ©
        textView.isAutomaticDashSubstitutionEnabled = false // disables -- -> —
        textView.isAutomaticQuoteSubstitutionEnabled = false // disables " -> “ ”
        
        textView.delegate = context.coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func recalculateHeight(for textView: NSTextView) {
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        // Ensure layout is up to date
        layoutManager.ensureLayout(for: textContainer)

        let glyphRange = layoutManager.glyphRange(for: textContainer)
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let height = ceil(boundingRect.height)
        
        DispatchQueue.main.async {
            self.calculatedHeight = height + 15
        }
    }
}
