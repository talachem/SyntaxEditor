# A Syntax Editor for SwiftUI

This is basically a Markdown Syntax Editor for SwiftUI. It was inspired by [HighlightedTextEditor](https://github.com/kyle-n/HighlightedTextEditor), which I still believe to be surpior to this one. But I needed something a little bit different. Hence I searched for tutorials and found this [one](https://sebwhitfield.medium.com/building-a-code-editor-using-swiftui-bb74819b5c1f).

What I needed was not just one editor view, I wanted to stack several editors view in a scroll view, since NSTextView does not play nice with this, there was some trickery and now it works. More importantly I wanted to be able to extract syntax highlighted snippets from text, read tags. This was achieved by the editor returning every string, that gets text attributes.

This can be done like so:

```swift
SyntaxEditor(text: $text)
    .stylingResults { styles in
        ...
    }
```

Similarly it can return pasted text on `onPaste` in a closure. And what I finally needed was a simple text viewer, which uses the same syntax rules. Hence the syntax text viewer, which can be used like so:

```swift
SyntaxViewer(text: text)
```

This is a normal SwiftUI text view with attributed strings. So it's nothing fancy. The text editor has different inits, where background colors, syntax rules or editor themes can be defined. Syntax styling rules are still something that is very verbose and needs a lot of work. Here's how some basics are created:

```swift
SyntaxStyleRule(glyphs: ["_", "*", "/"], size: baseFontSize, style: [.italic], glyphRange: .leadingAndTrailing(1, 1)),
SyntaxStyleRule(glyphs: ["__", "**", "//"], size: baseFontSize, style: [.bold], glyphRange: .leadingAndTrailing(2, 2)), 
```

But they can be created from regex patterns as well:

```swift
SyntaxStyleRule(
    pattern: "^>.*",
    options: [.anchorsMatchLines],
    font: .quote,
    size: baseFontSize,
    alignment: .right,
    glyphRange: .leadingOnly(1)
)
```
