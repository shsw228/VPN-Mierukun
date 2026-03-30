import AppKit
import Foundation
import VPNMierukunSharedModels

package enum OverlayColorSupport {
    package static func color(hex: String, alpha: Double, fallback: NSColor = .systemGray) -> NSColor {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard sanitized.count == 6,
              let value = Int(sanitized, radix: 16) else {
            return fallback
        }

        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    package static func rgbaHexString(hex: String, alpha: Double) -> String {
        let rgbColor = color(hex: hex, alpha: alpha).usingColorSpace(.deviceRGB) ?? .systemGray
        let red = Int((rgbColor.redComponent * 255).rounded())
        let green = Int((rgbColor.greenComponent * 255).rounded())
        let blue = Int((rgbColor.blueComponent * 255).rounded())
        let alpha = Int((rgbColor.alphaComponent * 255).rounded())
        return String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
    }

    package static func value(from color: NSColor) -> OverlayColorValue? {
        guard let deviceRGBColor = color.usingColorSpace(.deviceRGB) else {
            return nil
        }

        let red = Int((deviceRGBColor.redComponent * 255).rounded())
        let green = Int((deviceRGBColor.greenComponent * 255).rounded())
        let blue = Int((deviceRGBColor.blueComponent * 255).rounded())
        let normalizedHex = String(format: "#%02X%02X%02X", red, green, blue)
        let normalizedAlpha = min(max(Double(deviceRGBColor.alphaComponent), 0), 1)
        return OverlayColorValue(hex: normalizedHex, alpha: normalizedAlpha)
    }
}

package extension AppSettings {
    func overlayColor(for state: VPNDisplayState) -> NSColor {
        OverlayColorSupport.color(hex: colorHex(for: state), alpha: alpha(for: state))
    }
}
