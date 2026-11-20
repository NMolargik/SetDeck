// Renders the SetDeck 3.0 store backgrounds. swiftc -O bg.swift -o /tmp/setdeck-bg && /tmp/setdeck-bg <outdir>
// Optional: bg <outdir> <name> <w> <h> <glowX 0-1> <glowY 0-1> <card width px> for one custom canvas (header, search).
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
let A = CommandLine.arguments
var sizes: [(String, Int, Int)] = [("iphone", 1320, 2868), ("ipad", 2064, 2752), ("duo-outer", 1398, 2034), ("duo-unfolded", 2853, 2007)]
var custom: (cx: CGFloat, cy: CGFloat, card: CGFloat)? = nil
if A.count > 7 { sizes = [(A[2], Int(A[3])!, Int(A[4])!)]; custom = (CGFloat(Double(A[5])!), CGFloat(Double(A[6])!), CGFloat(Double(A[7])!)) }
let outDir = A.count > 1 ? A[1] : "."
let space = CGColorSpace(name: CGColorSpace.sRGB)!
func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [CGFloat((hex >> 16) & 255) / 255, CGFloat((hex >> 8) & 255) / 255, CGFloat(hex & 255) / 255, a])!
}
for (name, w, h) in sizes {
    let W = CGFloat(w), H = CGFloat(h)
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.translateBy(x: 0, y: H); ctx.scaleBy(x: 1, y: -1)
    // Vertical gradient #07090A -> #0B110E
    let grad = CGGradient(colorsSpace: space, colors: [rgb(0x07090A), rgb(0x0B110E)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: H), options: [])
    let centre = custom.map { CGPoint(x: W * $0.cx, y: H * $0.cy) } ?? CGPoint(x: W / 2, y: H * 0.5)
    let base = custom?.card ?? min(W, H * 0.8)
    // Soft green glow, 20% at the centre fading out.
    let glow = CGGradient(colorsSpace: space, colors: [rgb(0x4FC290, 0.20), rgb(0x4FC290, 0.08), rgb(0x4FC290, 0)] as CFArray, locations: [0, 0.5, 1])!
    ctx.drawRadialGradient(glow, startCenter: centre, startRadius: 0, endCenter: centre, endRadius: base * 0.75, options: [])
    // The new icon's fan of three card outlines (front card plus two tilted -16 and +16 degrees about a pivot below the cards, as in
    // AppIcon.icon: card 420 x 575, radius 75, pivot 367.5 below the card centre), large, low in the canvas and cropped by the edge, about 5% white.
    let cardW = base * 0.95, k = cardW / 420, cardH = 575 * k, r = 75 * k
    let front = CGPoint(x: centre.x + W * 0.02, y: centre.y + H * 0.34)
    let pivot = CGPoint(x: front.x, y: front.y + 367.5 * k)
    ctx.setStrokeColor(rgb(0xFFFFFF, 0.05)); ctx.setLineWidth(max(3, cardW * 0.008)); ctx.setLineJoin(.round)
    for ang in [-16.0, 16.0, 0.0] {
        ctx.saveGState()
        ctx.translateBy(x: pivot.x, y: pivot.y)
        ctx.rotate(by: CGFloat(ang) * .pi / 180)
        let rect = CGRect(x: -cardW / 2, y: -367.5 * k - cardH / 2, width: cardW, height: cardH)
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil))
        ctx.strokePath()
        ctx.restoreGState()
    }
    let image = ctx.makeImage()!
    let url = URL(fileURLWithPath: outDir).appendingPathComponent("\(name).png") as CFURL
    let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil); CGImageDestinationFinalize(dest)
}
