// montage.swift <out.png> <thumbHeight> <file>...: one row (or wrapped) contact sheet on near-black
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
let a = CommandLine.arguments; let th = CGFloat(Double(a[2])!); let files = Array(a.dropFirst(3))
let imgs: [CGImage] = files.map { CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(URL(fileURLWithPath: $0) as CFURL, nil)!, 0, nil)! }
let gap: CGFloat = 24
let ws = imgs.map { th * CGFloat($0.width) / CGFloat($0.height) }
let maxRow: CGFloat = 4200
var rows: [[Int]] = [[]]; var cur: CGFloat = gap
for i in imgs.indices { if cur + ws[i] + gap > maxRow && !rows[rows.count - 1].isEmpty { rows.append([]); cur = gap }; rows[rows.count - 1].append(i); cur += ws[i] + gap }
let W = Int(maxRow), H = Int(CGFloat(rows.count) * (th + gap) + gap)
let sp = CGColorSpace(name: CGColorSpace.sRGB)!
let c = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: sp, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
c.setFillColor(CGColor(colorSpace: sp, components: [0.12, 0.14, 0.13, 1])!); c.fill(CGRect(x: 0, y: 0, width: W, height: H))
c.interpolationQuality = .high
for (r, row) in rows.enumerated() { var x = gap; let y = CGFloat(H) - gap - CGFloat(r + 1) * th - CGFloat(r) * gap
  for i in row { c.draw(imgs[i], in: CGRect(x: x, y: y, width: ws[i], height: th)); x += ws[i] + gap } }
let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(d, c.makeImage()!, nil); CGImageDestinationFinalize(d)
