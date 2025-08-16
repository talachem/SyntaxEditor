//
//  File.swift
//  SyntaxEditor
//
//  Created by Johannes Bilk on 15.08.25.
//

import Foundation
import AppKit

extension SyntaxEditorCore.Coordinator {
    func highlightSearchResults(_ ranges: [NSRange]) {
        guard let textStorage = textView?.textStorage else { return }
        
        // Remove old search highlight attributes
        textStorage.removeAttribute(.backgroundColor,
                                    range: NSRange(location: 0, length: textStorage.length))
        
        // Add new highlights
        for range in ranges {
            textStorage.addAttribute(.backgroundColor,
                                     value: NSColor.yellow.withAlphaComponent(0.5),
                                     range: range)
        }
    }
    
    func updateSearchHighlights(for searchTerm: String?) {
        guard let textView = textView,
              let term = searchTerm, !term.isEmpty else {
            // Clear highlights if search term is empty
            highlightSearchResults([])
            return
        }
        
        let nsText = textView.string as NSString
        var searchRange = NSRange(location: 0, length: nsText.length)
        var results: [NSRange] = []
        
        while searchRange.location < nsText.length {
            let foundRange = nsText.range(of: term, options: [.caseInsensitive], range: searchRange)
            if foundRange.location != NSNotFound {
                results.append(foundRange)
                searchRange = NSRange(location: foundRange.location + foundRange.length,
                                      length: nsText.length - (foundRange.location + foundRange.length))
            } else {
                break
            }
        }
        
        highlightSearchResults(results)
    }
}
