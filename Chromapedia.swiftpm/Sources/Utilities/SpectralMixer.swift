import SwiftUI

// sRGB <-> linear conversions and hex parsing
enum ColorConverter {

    static func sRGBToLinear(_ v: Double) -> Double {
        v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }

    static func linearToSRGB(_ v: Double) -> Double {
        v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1.0 / 2.4) - 0.055
    }

    static func hexToSRGB(_ hex: String) -> (Double, Double, Double) {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var value: UInt64 = 0
        Scanner(string: h).scanHexInt64(&value)
        return (
            Double((value >> 16) & 0xFF) / 255.0,
            Double((value >> 8)  & 0xFF) / 255.0,
            Double( value        & 0xFF) / 255.0
        )
    }

    static func sRGBToHex(_ r: Double, _ g: Double, _ b: Double) -> String {
        let ri = Int((max(0, min(1, r)) * 255).rounded())
        let gi = Int((max(0, min(1, g)) * 255).rounded())
        let bi = Int((max(0, min(1, b)) * 255).rounded())
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }

    static func colorToSRGB(_ color: Color) -> (Double, Double, Double) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

// power-mean blending in linear RGB (p=0.25) for paint-like mixing
enum KubelkaMunkMixer {

    // p=0.25 sits between additive (p=1) and multiplicative (p->0)
    private static let mixPower: Double = 0.25
    private static let epsilon: Double = 0.001

    static func mix(colors: [Color], weights: [Double]? = nil) -> Color {
        guard !colors.isEmpty else { return .gray }
        let count = min(colors.count, 5)

        var w: [Double]
        if let provided = weights {
            let sum = provided.prefix(count).reduce(0.0, +)
            w = sum > 0
                ? provided.prefix(count).map { $0 / sum }
                : [Double](repeating: 1.0 / Double(count), count: count)
        } else {
            w = [Double](repeating: 1.0 / Double(count), count: count)
        }

        var linears = [(Double, Double, Double)]()
        for i in 0..<count {
            let (sr, sg, sb) = ColorConverter.colorToSRGB(colors[i])
            linears.append((
                max(epsilon, ColorConverter.sRGBToLinear(sr)),
                max(epsilon, ColorConverter.sRGBToLinear(sg)),
                max(epsilon, ColorConverter.sRGBToLinear(sb))
            ))
        }

        let p = mixPower
        var rSum = 0.0, gSum = 0.0, bSum = 0.0
        for i in 0..<count {
            rSum += w[i] * pow(linears[i].0, p)
            gSum += w[i] * pow(linears[i].1, p)
            bSum += w[i] * pow(linears[i].2, p)
        }
        let invP = 1.0 / p
        let mr = pow(max(0, rSum), invP)
        let mg = pow(max(0, gSum), invP)
        let mb = pow(max(0, bSum), invP)

        let sr = ColorConverter.linearToSRGB(max(0, min(1, mr)))
        let sg = ColorConverter.linearToSRGB(max(0, min(1, mg)))
        let sb = ColorConverter.linearToSRGB(max(0, min(1, mb)))

        return Color(
            red:   max(0, min(1, sr)),
            green: max(0, min(1, sg)),
            blue:  max(0, min(1, sb))
        )
    }

    static func mix(_ c1: Color, _ c2: Color, ratio: Double = 0.5) -> Color {
        mix(colors: [c1, c2], weights: [1.0 - ratio, ratio])
    }

    static func mix(_ c1: Color, _ c2: Color, _ c3: Color) -> Color {
        mix(colors: [c1, c2, c3])
    }
}
