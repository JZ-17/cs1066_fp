// Regenerate:  swift Tools/makeicon.swift Imposter/Assets.xcassets/AppIcon.appiconset/AppIcon.png

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Imposter app icon: a hooded figure cut out of the International Orange
// sunset the app uses. Drawn bottom-left origin, 1024 square, fully opaque.

let size = 1024
let cs = CGColorSpaceCreateDeviceRGB()

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [
        CGFloat((hex >> 16) & 0xFF) / 255,
        CGFloat((hex >> 8) & 0xFF) / 255,
        CGFloat(hex & 0xFF) / 255,
        a,
    ])!
}

let amber = rgb(0xFFB347)
let ember = rgb(0xFF7A3D)
let orange = rgb(0xE04A1F)
let crimson = rgb(0xA32330)
let cloak = rgb(0x1C0B22)   // near-black plum
let hollow = rgb(0x060208)  // inside of the hood

guard let ctx = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0, space: cs,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("context") }

let s = CGFloat(size)
func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

// ---------------------------------------------------------------- background

let sky = CGGradient(
    colorsSpace: cs,
    colors: [crimson, orange, ember, amber] as CFArray,
    locations: [0, 0.42, 0.72, 1]
)!
ctx.drawLinearGradient(sky, start: pt(0, Double(s)), end: pt(0, 0), options: [])

let vignette = CGGradient(
    colorsSpace: cs,
    colors: [rgb(0x2A1030, 0), rgb(0x2A1030, 0.62)] as CFArray,
    locations: [0.38, 1]
)!
ctx.drawRadialGradient(
    vignette,
    startCenter: pt(512, 530), startRadius: 0,
    endCenter: pt(512, 530), endRadius: Double(s) * 0.8,
    options: []
)

// -------------------------------------------------------------------- figure
// Hood sits on a shoulder break, shoulders fall into a draped cloak. The apex
// leans slightly left so the cowl reads as cloth rather than a cone.

let figure = CGMutablePath()
figure.move(to: pt(170, 100))
figure.addCurve(to: pt(292, 506), control1: pt(206, 252), control2: pt(248, 410))   // left hem up
figure.addCurve(to: pt(388, 628), control1: pt(318, 556), control2: pt(352, 598))   // left shoulder
figure.addCurve(to: pt(494, 892), control1: pt(398, 742), control2: pt(416, 858))   // hood, left
figure.addCurve(to: pt(624, 636), control1: pt(580, 890), control2: pt(614, 756))   // hood, right
figure.addCurve(to: pt(722, 512), control1: pt(636, 600), control2: pt(672, 556))   // right shoulder
figure.addCurve(to: pt(856, 100), control1: pt(772, 414), control2: pt(818, 254))   // right hem down
figure.closeSubpath()

// Warm halo so the sunset appears to wrap the fabric.
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 52, color: rgb(0xFF7A3D, 0.9))
ctx.setFillColor(cloak)
ctx.addPath(figure)
ctx.fillPath()
ctx.restoreGState()

ctx.setFillColor(cloak)
ctx.addPath(figure)
ctx.fillPath()

// --------------------------------------------------- shading inside the cloak

ctx.saveGState()
ctx.addPath(figure)
ctx.clip()

// Light falls from the upper left, so that edge of the cloak lifts.
let rim = CGGradient(
    colorsSpace: cs,
    colors: [rgb(0xFF7A3D, 0.42), rgb(0xFF7A3D, 0)] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(rim, start: pt(250, 800), end: pt(560, 430), options: [])

// Drapery: darker creases, then one lit fold catching the same light.
ctx.setLineCap(.round)
let creases: [(Double, Double, Double, Double)] = [
    (386, 600, 318, 110),
    (470, 580, 452, 104),
    (556, 584, 596, 108),
    (628, 596, 712, 112),
]
ctx.setStrokeColor(rgb(0x000000, 0.34))
ctx.setLineWidth(15)
for (x1, y1, x2, y2) in creases {
    ctx.move(to: pt(x1, y1))
    ctx.addQuadCurve(to: pt(x2, y2), control: pt((x1 + x2) / 2 - 16, (y1 + y2) / 2))
    ctx.strokePath()
}

ctx.setStrokeColor(rgb(0xFF9A5A, 0.20))
ctx.setLineWidth(9)
ctx.move(to: pt(352, 596))
ctx.addQuadCurve(to: pt(286, 120), control: pt(300, 350))
ctx.strokePath()

// Shoulder seam, a short crease where the hood meets the cloak.
ctx.setStrokeColor(rgb(0x000000, 0.30))
ctx.setLineWidth(12)
ctx.move(to: pt(398, 614))
ctx.addQuadCurve(to: pt(620, 620), control: pt(508, 566))
ctx.strokePath()

ctx.restoreGState()

// ---------------------------------------------------------------- hood & face

// The opening: a soft oval of darkness set into the hood.
let opening = CGMutablePath()
opening.addEllipse(in: CGRect(x: 437, y: 652, width: 142, height: 186))
ctx.setFillColor(hollow)
ctx.addPath(opening)
ctx.fillPath()

// Cowl rim catching light along the top edge of the opening.
ctx.saveGState()
ctx.setStrokeColor(rgb(0xFFB347, 0.30))
ctx.setLineWidth(10)
ctx.setLineCap(.round)
ctx.addArc(center: pt(508, 745), radius: 80, startAngle: .pi * 0.18, endAngle: .pi * 0.82, clockwise: false)
ctx.strokePath()
ctx.restoreGState()

// Eyes.
for eyeX in [481.0, 535.0] {
    let eye = CGRect(x: eyeX - 15, y: 742, width: 30, height: 19)
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 24, color: rgb(0xFFB347, 0.95))
    ctx.setFillColor(amber)
    ctx.fillEllipse(in: eye)
    ctx.restoreGState()
    ctx.setFillColor(amber)
    ctx.fillEllipse(in: eye)
}

// ------------------------------------------------------------------------ fog

let fog = CGGradient(
    colorsSpace: cs,
    colors: [rgb(0xFFC98A, 0), rgb(0xFFC98A, 0.32), rgb(0xFFC98A, 0)] as CFArray,
    locations: [0, 0.5, 1]
)!
ctx.saveGState()
ctx.clip(to: CGRect(x: 0, y: 74, width: s, height: 216))
ctx.drawLinearGradient(fog, start: pt(0, 74), end: pt(0, 290), options: [])
ctx.restoreGState()

// ----------------------------------------------------------------------- save

guard let image = ctx.makeImage() else { fatalError("image") }
let out = URL(fileURLWithPath: CommandLine.arguments[1])
guard let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("destination") }
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out.path)")
