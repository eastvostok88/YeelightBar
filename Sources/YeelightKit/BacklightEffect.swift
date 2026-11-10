import Foundation

public struct BacklightEffect: Codable, Identifiable {
    public enum Pattern: String, Codable, CaseIterable {
        case pulse, cycle, starlight, fire, wave, ripple, steady
    }

    public var id = UUID()
    public var name: String
    public var pattern: Pattern
    public var colors: [Int]
    public var seconds: Double
    public var intensity: Double = 0.75
    public var reversed = false

    public init(name: String, pattern: Pattern, colors: [Int], seconds: Double, reversed: Bool = false) {
        self.name = name
        self.pattern = pattern
        self.colors = colors
        self.seconds = seconds
        self.reversed = reversed
    }

    public static let presets: [Self] = {
        let rainbow = [0xFF284D, 0xFF9D24, 0xFFE653, 0x22E67D, 0x3A8CFF, 0xA34BFF]
        return [
            Self(name: "Pulse", pattern: .pulse, colors: [0x7D4FFF], seconds: 4),
            Self(name: "Dual Breathing", pattern: .pulse, colors: [0x1976FF, 0xFF357D], seconds: 6),
            Self(name: "Starlight", pattern: .starlight, colors: [0x4265FF, 0xCACBFF], seconds: 6),
            Self(name: "Rainbow", pattern: .cycle, colors: rainbow, seconds: 9),
            Self(name: "Rainbow Reverse", pattern: .cycle, colors: rainbow, seconds: 9, reversed: true),
            Self(name: "Aurora", pattern: .wave, colors: [0x00E69A, 0x2874FF, 0x7D4BFF], seconds: 12),
            Self(name: "Fire", pattern: .fire, colors: [0xA12004, 0xFF5620, 0xFFBA52], seconds: 7),
            Self(name: "Ocean Ripple", pattern: .ripple, colors: [0x0266E9, 0x12DDE7], seconds: 5),
            Self(name: "Sunset Cycle", pattern: .cycle, colors: [0xFF8C47, 0xF24783, 0x7952CD], seconds: 14),
            Self(name: "Bias Light", pattern: .steady, colors: [0xFFDCB8], seconds: 5)
        ]
    }()

    public func rgb(at elapsed: Double) -> Int {
        let palette = colors.isEmpty ? [0xFFFFFF] : colors
        let progress = max(0, elapsed) / max(2, seconds)
        let cycle = progress.truncatingRemainder(dividingBy: 1)
        let phase = reversed && cycle > 0 ? 1 - cycle : cycle
        let position = phase * Double(palette.count)
        let index = Int(position) % palette.count
        let fraction = position - position.rounded(.down)
        let cosPulse = (1 - cos(phase * 2 * .pi)) / 2
        let base = palette[index]
        let next = palette[(index + 1) % palette.count]
        let blend = (1 - cos(fraction * .pi)) / 2
        let amount: Double
        let gain: Double
        switch pattern {
        case .pulse:
            let paletteCycle = Int(progress.rounded(.down).truncatingRemainder(dividingBy: Double(palette.count)))
            let step = reversed ? (palette.count - paletteCycle) % palette.count : paletteCycle
            return Self.mix(palette[step], palette[step], amount: 0, gain: intensity * (0.08 + 0.92 * cosPulse))
        case .starlight:
            amount = pow(cosPulse, 5)
            gain = 0.12 + 0.88 * amount
        case .fire:
            amount = blend
            gain = 0.78 + 0.12 * sin(phase * 6 * .pi) + 0.10 * cos(phase * 10 * .pi)
        case .ripple:
            amount = blend
            gain = 0.24 + 0.76 * pow(cosPulse, 2)
        case .wave:
            amount = blend
            gain = 0.55 + 0.45 * cosPulse
        case .cycle:
            amount = fraction
            gain = 1
        case .steady:
            return Self.mix(palette[0], palette[0], amount: 0, gain: intensity)
        }
        return Self.mix(base, next, amount: amount, gain: intensity * gain)
    }

    private static func mix(_ a: Int, _ b: Int, amount: Double, gain: Double) -> Int {
        [16, 8, 0].reduce(0) { rgb, shift in
            let from = Double((a >> shift) & 255)
            let to = Double((b >> shift) & 255)
            let value = Int(min(255, max(0, (from + (to - from) * amount) * gain)).rounded())
            return rgb | (value << shift)
        }
    }
}
