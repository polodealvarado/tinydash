import Cocoa

@main
struct GenerateIcon {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("Usage: generate-icon <output.iconset>")
        }
        let directory = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for size in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let pixels = size * scale
                let image = makePencilImage(size: CGFloat(pixels), background: true)
                let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels,
                    pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
                image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
                NSGraphicsContext.restoreGraphicsState()
                let suffix = scale == 2 ? "@2x" : ""
                let file = directory.appendingPathComponent("icon_\(size)x\(size)\(suffix).png")
                try bitmap.representation(using: .png, properties: [:])!.write(to: file)
            }
        }
    }
}
