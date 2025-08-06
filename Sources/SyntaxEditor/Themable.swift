//
//  Themable.swift
//  CodeEditor
//
//  Created by Johannes Bilk on 27.07.25.
//

import SwiftUI
import AppKit

protocol Themable {
    var syntaxStyleRules: [SyntaxStyleRule] { get }
    var backgroundColor: NSColor { get }
}
