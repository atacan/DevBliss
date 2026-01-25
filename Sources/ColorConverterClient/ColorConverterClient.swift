import Dependencies
import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct ColorConverterClient {
    public var convert: @Sendable (String, ColorConverterConfig) throws -> ColorConversionResult
}

public struct ColorConverterConfig: Equatable, Codable {
    public var uppercaseHex: Bool
    public var includeAlpha: Bool

    public init(uppercaseHex: Bool = true, includeAlpha: Bool = false) {
        self.uppercaseHex = uppercaseHex
        self.includeAlpha = includeAlpha
    }
}

public struct ColorConversionResult: Equatable, Codable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double
    public var hex: String
    public var rgb: String
    public var rgba: String
    public var hsl: String
    public var hsla: String
    public var summary: String
}

extension ColorConverterClient: DependencyKey {
    public static let liveValue = Self(
        convert: { input, config in
            let components = try parseColorComponents(from: input)
            let normalized = normalizeColor(components)

            let hex = hexString(from: normalized, uppercase: config.uppercaseHex, includeAlpha: config.includeAlpha)
            let rgb = rgbString(from: normalized, includeAlpha: false)
            let rgba = rgbString(from: normalized, includeAlpha: true)
            let hsl = hslString(from: normalized, includeAlpha: false)
            let hsla = hslString(from: normalized, includeAlpha: true)

            let summary = [
                "HEX: \(hex)",
                "RGB: \(rgb)",
                "RGBA: \(rgba)",
                "HSL: \(hsl)",
                "HSLA: \(hsla)",
            ]
            .joined(separator: "\n")

            return ColorConversionResult(
                red: normalized.red,
                green: normalized.green,
                blue: normalized.blue,
                alpha: normalized.alpha,
                hex: hex,
                rgb: rgb,
                rgba: rgba,
                hsl: hsl,
                hsla: hsla,
                summary: summary
            )
        }
    )
}

extension DependencyValues {
    public var colorConverter: ColorConverterClient {
        get { self[ColorConverterClient.self] }
        set { self[ColorConverterClient.self] = newValue }
    }
}

public enum ColorConverterError: LocalizedError {
    case emptyInput
    case invalidFormat

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Enter a color value"
        case .invalidFormat:
            return "Unsupported color format"
        }
    }
}

private struct ColorComponents {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
}

private func parseColorComponents(from input: String) throws -> ColorComponents {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw ColorConverterError.emptyInput }

    if let hexComponents = parseHex(trimmed) {
        return hexComponents
    }

    if let rgbComponents = parseRGB(trimmed) {
        return rgbComponents
    }

    throw ColorConverterError.invalidFormat
}

private func parseHex(_ input: String) -> ColorComponents? {
    var hex = input
    if hex.hasPrefix("#") { hex.removeFirst() }
    hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)

    let length = hex.count
    guard [3, 4, 6, 8].contains(length) else { return nil }

    let expanded: String
    if length == 3 || length == 4 {
        expanded = hex.map { "\($0)\($0)" }.joined()
    } else {
        expanded = hex
    }

    let valueLength = expanded.count
    guard valueLength == 6 || valueLength == 8 else { return nil }

    let red = hexPair(expanded, start: 0)
    let green = hexPair(expanded, start: 2)
    let blue = hexPair(expanded, start: 4)
    let alpha = valueLength == 8 ? hexPair(expanded, start: 6) : 255

    guard let r = red, let g = green, let b = blue, let a = alpha else { return nil }

    return ColorComponents(
        red: Double(r) / 255.0,
        green: Double(g) / 255.0,
        blue: Double(b) / 255.0,
        alpha: Double(a) / 255.0
    )
}

private func parseRGB(_ input: String) -> ColorComponents? {
    let lower = input.lowercased()
    let isRGBA = lower.hasPrefix("rgba(")
    let isRGB = lower.hasPrefix("rgb(")
    guard isRGBA || isRGB else { return nil }

    guard let start = input.firstIndex(of: "("), let end = input.lastIndex(of: ")") else { return nil }
    let contents = input[input.index(after: start)..<end]
    let parts = contents.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

    if isRGB, parts.count != 3 { return nil }
    if isRGBA, parts.count != 4 { return nil }

    guard let r = Double(parts[0]), let g = Double(parts[1]), let b = Double(parts[2]) else { return nil }
    let alpha = isRGBA ? Double(parts[3]) ?? 1.0 : 1.0

    return ColorComponents(
        red: clamp(r / 255.0),
        green: clamp(g / 255.0),
        blue: clamp(b / 255.0),
        alpha: clamp(alpha)
    )
}

private func normalizeColor(_ components: ColorComponents) -> ColorComponents {
    #if os(macOS)
    let color = NSColor(
        calibratedRed: CGFloat(components.red),
        green: CGFloat(components.green),
        blue: CGFloat(components.blue),
        alpha: CGFloat(components.alpha)
    )
    guard let srgb = color.usingColorSpace(.sRGB) else { return components }
    return ColorComponents(
        red: Double(srgb.redComponent),
        green: Double(srgb.greenComponent),
        blue: Double(srgb.blueComponent),
        alpha: Double(srgb.alphaComponent)
    )
    #else
    let color = UIColor(
        red: CGFloat(components.red),
        green: CGFloat(components.green),
        blue: CGFloat(components.blue),
        alpha: CGFloat(components.alpha)
    )
    guard let cgColor = color.cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil),
          let comps = cgColor.components else { return components }
    let r = comps.count > 0 ? comps[0] : 0
    let g = comps.count > 1 ? comps[1] : 0
    let b = comps.count > 2 ? comps[2] : 0
    let a = comps.count > 3 ? comps[3] : 1
    return ColorComponents(red: Double(r), green: Double(g), blue: Double(b), alpha: Double(a))
    #endif
}

private func hexPair(_ string: String, start: Int) -> Int? {
    let startIndex = string.index(string.startIndex, offsetBy: start)
    let endIndex = string.index(startIndex, offsetBy: 2)
    return Int(string[startIndex..<endIndex], radix: 16)
}

private func hexString(from components: ColorComponents, uppercase: Bool, includeAlpha: Bool) -> String {
    let r = Int(round(components.red * 255))
    let g = Int(round(components.green * 255))
    let b = Int(round(components.blue * 255))
    let a = Int(round(components.alpha * 255))

    let format = uppercase ? "%02X" : "%02x"
    var hex = String(format: "#\(format)\(format)\(format)", r, g, b)
    if includeAlpha {
        hex += String(format: format, a)
    }
    return hex
}

private func rgbString(from components: ColorComponents, includeAlpha: Bool) -> String {
    let r = Int(round(components.red * 255))
    let g = Int(round(components.green * 255))
    let b = Int(round(components.blue * 255))
    if includeAlpha {
        return "rgba(\(r), \(g), \(b), \(formatAlpha(components.alpha)))"
    }
    return "rgb(\(r), \(g), \(b))"
}

private func hslString(from components: ColorComponents, includeAlpha: Bool) -> String {
    let (h, s, l) = rgbToHsl(components)
    let hText = String(format: "%.0f", h)
    let sText = String(format: "%.1f", s)
    let lText = String(format: "%.1f", l)

    if includeAlpha {
        return "hsla(\(hText), \(sText)%, \(lText)%, \(formatAlpha(components.alpha)))"
    }

    return "hsl(\(hText), \(sText)%, \(lText)%)"
}

private func rgbToHsl(_ components: ColorComponents) -> (Double, Double, Double) {
    let r = components.red
    let g = components.green
    let b = components.blue

    let maxValue = max(r, g, b)
    let minValue = min(r, g, b)
    let delta = maxValue - minValue

    var h: Double = 0
    let l = (maxValue + minValue) / 2

    let s: Double
    if delta == 0 {
        s = 0
    } else {
        s = delta / (1 - abs(2 * l - 1))
        if maxValue == r {
            h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxValue == g {
            h = ((b - r) / delta) + 2
        } else {
            h = ((r - g) / delta) + 4
        }
        h *= 60
        if h < 0 { h += 360 }
    }

    return (h, s * 100, l * 100)
}

private func formatAlpha(_ alpha: Double) -> String {
    let formatted = String(format: "%.3f", alpha)
    let trimmed = formatted.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
        .trimmingCharacters(in: CharacterSet(charactersIn: "."))
    return trimmed.isEmpty ? "0" : trimmed
}

private func clamp(_ value: Double) -> Double {
    min(max(value, 0), 1)
}
