import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Gera o favicon com a mesma marca da splash. Só roda no macOS — o emoji
// vem da fonte Apple Color Emoji, que é bitmap e o CoreText desenha em cor.
//
//   swift scripts/make_favicon.swift web/favicon.png 256
//
// Mesma marca da splash: 🏝️ sobre o sunsetGradient (coral -> sunset).
let coral = CGColor(srgbRed: 0xFF / 255, green: 0x6B / 255, blue: 0x6B / 255, alpha: 1)
let sunset = CGColor(srgbRed: 0xFF / 255, green: 0xA4 / 255, blue: 0x5B / 255, alpha: 1)

func render(size: CGFloat, to url: URL) {
    let px = Int(size)
    let space = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("sem contexto") }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Fundo: quadrado arredondado com o gradiente na diagonal.
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: size * 0.22, cornerHeight: size * 0.22, transform: nil))
    ctx.clip()
    let gradient = CGGradient(colorsSpace: space, colors: [coral, sunset] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: size, y: 0),
        options: []
    )
    ctx.restoreGState()

    // A ilha. Apple Color Emoji é bitmap: o CoreText desenha em cores.
    let font = CTFontCreateWithName("Apple Color Emoji" as CFString, size * 0.64, nil)
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(
            string: "🏝️",
            attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]
        )
    )
    var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
    let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))

    ctx.textPosition = CGPoint(
        x: (size - width) / 2,
        y: (size - (ascent + descent)) / 2 + descent
    )
    CTLineDraw(line, ctx)

    guard let image = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { fatalError("sem imagem") }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("ok \(url.path) (\(px)px)")
}

let out = CommandLine.arguments[1]
render(size: CGFloat(Int(CommandLine.arguments[2])!), to: URL(fileURLWithPath: out))
