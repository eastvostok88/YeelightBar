import XCTest
@testable import YeelightKit

final class AmbientContextTests: XCTestCase {
    func testSwitchingAwayCancelsPendingGame() {
        var context = AmbientContext(isAutomatic: true)
        context.observe(.game, at: 0)
        context.observe(.work, at: 1)
        XCTAssertNil(context.advance(at: 3))
        XCTAssertEqual(context.active, .work)
    }

    func testSameModeDoesNotRestartDelayAndWorkUsesExitDelay() {
        var context = AmbientContext(isAutomatic: true)
        context.observe(.game, at: 0)
        context.observe(.game, at: 1)
        XCTAssertNil(context.advance(at: 1.99))
        XCTAssertEqual(context.advance(at: 2), .game)
        context.observe(.work, at: 3)
        XCTAssertNil(context.advance(at: 7.99))
        XCTAssertEqual(context.advance(at: 8), .work)
    }

    func testManualSelectionCancelsPendingAutomation() {
        var context = AmbientContext(isAutomatic: true)
        context.observe(.game, at: 0)
        context.selectManually(.cinema)
        context.observe(.work, at: 1)
        XCTAssertNil(context.advance(at: 10))
        XCTAssertEqual(context.active, .cinema)

        context.resumeAutomatic(with: .work, at: 10)
        XCTAssertEqual(context.advance(at: 15), .work)
    }

    func testReplacingCandidateUsesTheNewDeadline() {
        var context = AmbientContext(isAutomatic: true)
        context.observe(.game, at: 0)
        context.observe(.cinema, at: 1)
        XCTAssertNil(context.advance(at: 2))
        XCTAssertEqual(context.advance(at: 3), .cinema)
    }

    func testRulesRoundTrip() throws {
        let rules = AmbientAppRules(byBundleID: ["org.example.cinema": .cinema])
        let decoded = try JSONDecoder().decode(AmbientAppRules.self, from: JSONEncoder().encode(rules))
        XCTAssertEqual(decoded.mode(for: "org.example.cinema"), .cinema)
    }

    func testInvalidOrUnassignedApplicationFallsBackToWork() {
        let rules = AmbientAppRules(byBundleID: ["org.example.game": .game])
        XCTAssertEqual(rules.mode(for: "org.example.game"), .game)
        XCTAssertEqual(rules.mode(for: "org.example.browser"), .work)
        XCTAssertEqual(rules.mode(for: nil), .work)
    }
}
