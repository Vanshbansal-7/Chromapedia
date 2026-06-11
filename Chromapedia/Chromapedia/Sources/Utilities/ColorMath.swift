// Chromapedia
// Utilities/ColorMath.swift — v2

import SwiftUI

// MARK: - Color Math Engine
enum ColorMath {

    // MARK: - Gamma-Corrected Linear RGB Blending (additive light)
    static func sRGBToLinear(_ v: CGFloat) -> CGFloat {
        v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }

    static func linearToSRGB(_ v: CGFloat) -> CGFloat {
        v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1.0 / 2.4) - 0.055
    }

    // MARK: - Subtractive Mixing (power-mean pipeline)
    // Delegates to SpectralMixer.KubelkaMunkMixer for paint-accurate
    // subtractive color mixing via power-mean (p=0.25) in linear RGB space.

    /// Subtractive (paint-like) mix of two colors via power-mean blending
    static func mixSubtractive(_ c1: Color, _ c2: Color, ratio: CGFloat = 0.5) -> Color {
        KubelkaMunkMixer.mix(c1, c2, ratio: Double(ratio))
    }

    /// Subtractive mix of three colors (equal weights)
    static func mixSubtractive(_ c1: Color, _ c2: Color, _ c3: Color) -> Color {
        KubelkaMunkMixer.mix(c1, c2, c3)
    }

    /// Raw CGFloat components (0-1)
    static func colorToComponents(_ color: Color) -> (CGFloat, CGFloat, CGFloat) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }

    /// Convert Color → (R, G, B) as 0-255 integers
    static func colorToRGB(_ color: Color) -> (Int, Int, Int) {
        let (r, g, b) = colorToComponents(color)
        return (Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }

    /// Convert (R,G,B) integers → HEX string with #
    static func rgbToHex(r: Int, g: Int, b: Int) -> String {
        String(format: "#%02X%02X%02X", clamp(r), clamp(g), clamp(b))
    }

    /// Convert Color → HEX string
    static func colorToHex(_ color: Color) -> String {
        let (r, g, b) = colorToRGB(color)
        return rgbToHex(r: r, g: g, b: b)
    }

    /// RGB 0-255 → HSL
    static func rgbToHSL(r: Int, g: Int, b: Int) -> HSLValues {
        let rf = CGFloat(r) / 255.0
        let gf = CGFloat(g) / 255.0
        let bf = CGFloat(b) / 255.0
        let mx = max(rf, gf, bf), mn = min(rf, gf, bf)
        let l  = (mx + mn) / 2.0
        var h: CGFloat = 0, s: CGFloat = 0
        if mx != mn {
            let d = mx - mn
            s = l > 0.5 ? d / (2.0 - mx - mn) : d / (mx + mn)
            switch mx {
            case rf: h = (gf - bf) / d + (gf < bf ? 6 : 0)
            case gf: h = (bf - rf) / d + 2
            default: h = (rf - gf) / d + 4
            }
            h /= 6.0
        }
        return HSLValues(h: Int(h * 360), s: Int(s * 100), l: Int(l * 100))
    }

    // MARK: - CIE Lab Color Space (perceptual accuracy)

    /// Convert sRGB (0-255) to CIE Lab
    static func rgbToLab(r: Int, g: Int, b: Int) -> (L: Double, a: Double, b: Double) {
        // sRGB → linear → XYZ (D65 illuminant)
        func linearize(_ v: Double) -> Double {
            v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        let rl = linearize(Double(r) / 255.0)
        let gl = linearize(Double(g) / 255.0)
        let bl = linearize(Double(b) / 255.0)

        // sRGB → XYZ (D65)
        var x = rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375
        var y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750
        var z = rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041

        // Normalize to D65 white point
        x /= 0.95047; y /= 1.00000; z /= 1.08883

        // XYZ → Lab
        func f(_ t: Double) -> Double {
            t > 0.008856 ? pow(t, 1.0/3.0) : (903.3 * t + 16.0) / 116.0
        }
        let fx = f(x), fy = f(y), fz = f(z)
        let L = 116.0 * fy - 16.0
        let a = 500.0 * (fx - fy)
        let bVal = 200.0 * (fy - fz)
        return (L, a, bVal)
    }

    /// CIEDE2000 perceptual color distance
    static func ciede2000(L1: Double, a1: Double, b1: Double,
                          L2: Double, a2: Double, b2: Double) -> Double {
        let kL = 1.0, kC = 1.0, kH = 1.0
        let pi = Double.pi

        let C1 = sqrt(a1*a1 + b1*b1)
        let C2 = sqrt(a2*a2 + b2*b2)
        let Cb = (C1 + C2) / 2.0

        let Cb7 = pow(Cb, 7)
        let G = 0.5 * (1.0 - sqrt(Cb7 / (Cb7 + pow(25.0, 7))))

        let a1p = a1 * (1.0 + G)
        let a2p = a2 * (1.0 + G)

        let C1p = sqrt(a1p*a1p + b1*b1)
        let C2p = sqrt(a2p*a2p + b2*b2)

        var h1p = atan2(b1, a1p) * 180.0 / pi
        if h1p < 0 { h1p += 360.0 }
        var h2p = atan2(b2, a2p) * 180.0 / pi
        if h2p < 0 { h2p += 360.0 }

        let dLp = L2 - L1
        let dCp = C2p - C1p

        var dhp: Double
        if C1p * C2p == 0 {
            dhp = 0
        } else if abs(h2p - h1p) <= 180.0 {
            dhp = h2p - h1p
        } else if h2p - h1p > 180.0 {
            dhp = h2p - h1p - 360.0
        } else {
            dhp = h2p - h1p + 360.0
        }
        let dHp = 2.0 * sqrt(C1p * C2p) * sin(dhp * pi / 360.0)

        let Lbp = (L1 + L2) / 2.0
        let Cbp = (C1p + C2p) / 2.0

        var Hbp: Double
        if C1p * C2p == 0 {
            Hbp = h1p + h2p
        } else if abs(h1p - h2p) <= 180.0 {
            Hbp = (h1p + h2p) / 2.0
        } else if h1p + h2p < 360.0 {
            Hbp = (h1p + h2p + 360.0) / 2.0
        } else {
            Hbp = (h1p + h2p - 360.0) / 2.0
        }

        let T = 1.0
            - 0.17 * cos((Hbp - 30.0) * pi / 180.0)
            + 0.24 * cos(2.0 * Hbp * pi / 180.0)
            + 0.32 * cos((3.0 * Hbp + 6.0) * pi / 180.0)
            - 0.20 * cos((4.0 * Hbp - 63.0) * pi / 180.0)

        let Lbp50sq = (Lbp - 50.0) * (Lbp - 50.0)
        let SL = 1.0 + 0.015 * Lbp50sq / sqrt(20.0 + Lbp50sq)
        let SC = 1.0 + 0.045 * Cbp
        let SH = 1.0 + 0.015 * Cbp * T

        let Cbp7 = pow(Cbp, 7)
        let RC = 2.0 * sqrt(Cbp7 / (Cbp7 + pow(25.0, 7)))
        let dtheta = 30.0 * exp(-((Hbp - 275.0) / 25.0) * ((Hbp - 275.0) / 25.0))
        let RT = -sin(2.0 * dtheta * pi / 180.0) * RC

        let valL = dLp / (kL * SL)
        let valC = dCp / (kC * SC)
        let valH = dHp / (kH * SH)

        return sqrt(valL*valL + valC*valC + valH*valH + RT * valC * valH)
    }

    /// Find closest named color using CIEDE2000 perceptual distance
    static func findClosestColor(r: Int, g: Int, b: Int) -> ColorItem {
        let target = rgbToLab(r: r, g: g, b: b)
        return ColorData.all.min {
            let lab1 = rgbToLab(r: $0.rgb.r, g: $0.rgb.g, b: $0.rgb.b)
            let lab2 = rgbToLab(r: $1.rgb.r, g: $1.rgb.g, b: $1.rgb.b)
            return ciede2000(L1: target.L, a1: target.a, b1: target.b,
                           L2: lab1.L, a2: lab1.a, b2: lab1.b) <
                   ciede2000(L1: target.L, a1: target.a, b1: target.b,
                           L2: lab2.L, a2: lab2.a, b2: lab2.b)
        } ?? ColorData.all[0]
    }

    /// Complementary (180°)
    static func complementaryColor(from color: Color) -> Color {
        let ui = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double((h + 0.5).truncatingRemainder(dividingBy: 1)), saturation: Double(s), brightness: Double(b))
    }

    /// Luminance check for text color
    static func isLight(_ color: Color) -> Bool {
        let (r, g, b) = colorToRGB(color)
        let lum = 0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b)
        return lum > 160
    }

    private static func clamp(_ v: Int) -> Int { max(0, min(255, v)) }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8)  & 0xFF) / 255.0,
            blue:  Double( value        & 0xFF) / 255.0
        )
    }

    var hexString: String { ColorMath.colorToHex(self) }

    var isLight: Bool { ColorMath.isLight(self) }

    var textColor: Color { isLight ? .black.opacity(0.8) : .white }
}

// MARK: - String Extension
extension String {
    func toRGB() -> (Int, Int, Int) {
        let hex = self.hasPrefix("#") ? String(self.dropFirst()) : self
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        return (Int((value >> 16) & 0xFF), Int((value >> 8) & 0xFF), Int(value & 0xFF))
    }
}
