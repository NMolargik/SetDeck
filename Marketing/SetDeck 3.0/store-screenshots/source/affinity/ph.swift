// ph.swift <out.png> <w> <h> <radius>: placeholder device outline (transparent) for the Duo artboards
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
let a = CommandLine.arguments; let w = Int(a[2])!, h = Int(a[3])!, r = CGFloat(Double(a[4])!)
let sp = CGColorSpace(name: CGColorSpace.sRGB)!
let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: sp, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let rect = CGRect(x: 6, y: 6, width: w - 12, height: h - 12)
c.setFillColor(CGColor(colorSpace: sp, components: [1, 1, 1, 0.04])!)
c.addPath(CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)); c.fillPath()
c.setStrokeColor(CGColor(colorSpace: sp, components: [0.31, 0.76, 0.56, 0.5])!); c.setLineWidth(6); c.setLineDash(phase: 0, lengths: [40, 28])
c.addPath(CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)); c.strokePath()
let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(d, c.makeImage()!, nil); CGImageDestinationFinalize(d)
