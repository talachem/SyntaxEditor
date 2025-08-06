//
//  File.swift
//  SyntaxEditor
//
//  Created by Johannes Bilk on 03.08.25.
//

import Foundation
import AppKit

public class PastingTextView: NSTextView {
    var onPaste: ((String) -> Void)?

    public override func paste(_ sender: Any?) {
        if let pasteboardString = NSPasteboard.general.string(forType: .string) {
            onPaste?(pasteboardString)
        }
        super.paste(sender)
    }
}
