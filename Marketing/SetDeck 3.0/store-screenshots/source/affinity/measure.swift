// measure.swift <postscript> <line>... : prints each line's advance width at 100 pt
import CoreText
import Foundation
let a = CommandLine.arguments
let font = CTFontCreateWithName(a[1] as CFString, 100, nil)
for s in a.dropFirst(2) {
    let str = NSAttributedString(string: s, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
    let line = CTLineCreateWithAttributedString(str)
    print(CTLineGetTypographicBounds(line, nil, nil, nil))
}
