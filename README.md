# A Syntax Editor for SwiftUI

This is a Markdown-style syntax editor built with SwiftUI. It was inspired by HighlightedTextEditor, which I still believe is superior in many ways. However, I needed something slightly different.

While searching for approaches, I found this tutorial, which helped form the foundation of this project.

Why this exists

I needed:
- Multiple editor views in a scroll view — NSTextView doesn’t handle this well, so some workaround code was required.
- Extraction of syntax-highlighted snippets — not just to render them, but to capture “tags” from the text.
- A lightweight syntax viewer — for displaying pre-styled text without editing.

The editor now:
- Returns each styled string via `.stylingResults { ... }`
- Supports onPaste closures to handle pasted text
- Has a SyntaxViewer for read-only, syntax-styled text


## Usage

Editor example:

```swift
SyntaxEditor(text: $text)
    .stylingResults { styles in
        ...
    }
```

Viewer example:

```swift
SyntaxViewer(text: text)
```

The viewer is just a SwiftUI Text view with attributed strings, so it’s lightweight and fast.

## Customization

The editor supports:
- Background colors
- Syntax rules
- Editor themes
- Styling via glyphs **or** regex


**Glyph example:**
```swift
SyntaxStyleRule(
    glyphs: ["_", "*", "/"],
    size: baseFontSize,
    style: [.italic],
    glyphRange: .leadingAndTrailing(1, 1)
),
SyntaxStyleRule(
    glyphs: ["__", "**", "//"],
    size: baseFontSize,
    style: [.bold],
    glyphRange: .leadingAndTrailing(2, 2)
) 
```

**Regex example:**
```swift
SyntaxStyleRule(
    pattern: "^>.*",
    options: [.anchorsMatchLines],
    font: .quote,
    size: baseFontSize,
    alignment: .right,
    glyphRange: .leadingOnly(1)
),
SyntaxStyleRule(
    pattern: "^//.*$",
    options: [.anchorsMatchLines],
    color: .gray,
    size: baseFontSize,
    glyphRange: .not
)
```
