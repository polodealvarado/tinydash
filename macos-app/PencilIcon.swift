import Cocoa

// One pencil drawing for both the menu bar template and the application icon.
func makePencilImage(size: CGFloat, background: Bool) -> NSImage {
    NSImage(size: NSSize(width: size, height: size), flipped: true) { _ in
        if background {
            NSColor(srgbRed: 0.404, green: 0.325, blue: 0.780, alpha: 1).setFill()
            NSBezierPath(roundedRect: NSRect(x: size * 0.07, y: size * 0.07,
                                            width: size * 0.86, height: size * 0.86),
                         xRadius: size * 0.19, yRadius: size * 0.19).fill()
        }
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        if background {
            transform.translateX(by: size / 6, yBy: size / 6)
            transform.scale(by: size / 36)
        } else {
            transform.scale(by: size / 24)
        }
        transform.concat()
        let pencil = NSBezierPath()
        pencil.move(to: NSPoint(x: 4, y: 20))
        pencil.line(to: NSPoint(x: 5.2, y: 15.2))
        pencil.line(to: NSPoint(x: 16, y: 4.4))
        pencil.curve(to: NSPoint(x: 18.8, y: 4.4),
                     controlPoint1: NSPoint(x: 16.77, y: 3.63),
                     controlPoint2: NSPoint(x: 18.03, y: 3.63))
        pencil.line(to: NSPoint(x: 19.6, y: 5.2))
        pencil.curve(to: NSPoint(x: 19.6, y: 8),
                     controlPoint1: NSPoint(x: 20.37, y: 5.97),
                     controlPoint2: NSPoint(x: 20.37, y: 7.23))
        pencil.line(to: NSPoint(x: 8.8, y: 18.8))
        pencil.close()
        pencil.move(to: NSPoint(x: 13.8, y: 6.6))
        pencil.line(to: NSPoint(x: 17.4, y: 10.2))
        pencil.move(to: NSPoint(x: 5.2, y: 15.2))
        pencil.line(to: NSPoint(x: 8.8, y: 18.8))
        pencil.lineWidth = 1.8
        pencil.lineCapStyle = .round
        pencil.lineJoinStyle = .round
        (background ? NSColor.white : NSColor.black).setStroke()
        pencil.stroke()
        NSGraphicsContext.restoreGraphicsState()
        return true
    }
}
