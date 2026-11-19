import CoreGraphics
import ImageIO
import Foundation
import UniformTypeIdentifiers
for p in CommandLine.arguments.dropFirst() {
  let u = URL(fileURLWithPath: p)
  let im = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(u as CFURL, nil)!, 0, nil)!
  let c = im.cropping(to: CGRect(x: 0, y: 130, width: im.width, height: im.height - 130))!
  let d = CGImageDestinationCreateWithURL(u as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(d, c, nil); CGImageDestinationFinalize(d)
}
