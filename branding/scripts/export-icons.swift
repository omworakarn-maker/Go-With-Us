import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Package the supplied artwork without redrawing or cropping it.
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let input = root.appendingPathComponent("Logo.png")
guard let source = CGImageSourceCreateWithURL(input as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError("Cannot read supplied Logo.png") }
let outputs: [(String, Int, CGFloat)] = [
    ("app-icon.png", 1024, 0.82), ("icon-512.png", 512, 0.82),
    ("icon-192.png", 192, 0.82), ("apple-touch-icon.png", 180, 0.82),
    ("icon-maskable-512.png", 512, 0.68)
]
for (name, side, fraction) in outputs {
    guard let context = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
                                  bytesPerRow: side * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError("Cannot create icon context") }
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: side, height: side))
    context.interpolationQuality = .high
    let scale = CGFloat(side) * fraction / CGFloat(max(image.width, image.height))
    let width = CGFloat(image.width) * scale
    let height = CGFloat(image.height) * scale
    context.draw(image, in: CGRect(x: (CGFloat(side) - width) / 2, y: (CGFloat(side) - height) / 2, width: width, height: height))
    let output = root.appendingPathComponent(name)
    guard let bitmap = context.makeImage(),
          let writer = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil) else { fatalError("Cannot write icon") }
    CGImageDestinationAddImage(writer, bitmap, nil)
    guard CGImageDestinationFinalize(writer) else { fatalError("Cannot finish icon") }
    print("Packaged \(name): \(side)×\(side), opaque background")
}
