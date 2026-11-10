import XCTest
@testable import YeelightKit

final class BacklightEffectTests: XCTestCase {
    func testTenPresetsProduceValidColors() {
        XCTAssertEqual(BacklightEffect.presets.count, 10)
        for effect in BacklightEffect.presets {
            for sample in 0...240 {
                XCTAssertTrue((0...0xFFFFFF).contains(effect.rgb(at: Double(sample) / 20)))
            }
        }
    }

    func testReverseRainbowUsesOppositePaletteOrder() {
        var effect = BacklightEffect(name: "Test", pattern: .cycle, colors: [0xFF0000, 0x00FF00, 0x0000FF], seconds: 6)
        effect.intensity = 1
        XCTAssertEqual(effect.rgb(at: 2), 0x00FF00)
        effect.reversed = true
        XCTAssertEqual(effect.rgb(at: 2), 0x0000FF)
    }

    func testPulseVariesBrightnessWithoutChangingHue() {
        let effect = BacklightEffect(name: "Test", pattern: .pulse, colors: [0xFF0000], seconds: 4)
        XCTAssertLessThan(effect.rgb(at: 0), effect.rgb(at: 2))
        XCTAssertEqual(effect.rgb(at: 2) & 0xFFFF, 0)
    }
}
