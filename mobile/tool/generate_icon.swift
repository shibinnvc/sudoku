import AppKit
import Foundation

let output = CommandLine.arguments[1]
let size = 1024
guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
      let context = NSGraphicsContext(bitmapImageRep: bitmap) else { fatalError("Could not create icon") }

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> NSColor {
  NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
color(247, 246, 242).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

let shapes: [(CGFloat, CGFloat, NSColor)] = [
  (234, 538, color(41, 88, 79)),
  (538, 538, color(96, 140, 127)),
  (234, 234, color(161, 183, 168)),
  (538, 234, color(58, 113, 98)),
]
for (x, y, fill) in shapes {
  let path = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: 252, height: 252), xRadius: 38, yRadius: 38)
  fill.setFill()
  path.fill()
}
color(210, 183, 127).setFill()
NSBezierPath(ovalIn: NSRect(x: 478, y: 478, width: 68, height: 68)).fill()
context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not encode icon") }
try data.write(to: URL(fileURLWithPath: output))
