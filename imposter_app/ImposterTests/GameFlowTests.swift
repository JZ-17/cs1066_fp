import XCTest
@testable import Imposter

final class GameFlowTests: XCTestCase {

    func testFlowStartsEmpty() {
        let flow = GameFlow()
        XCTAssertTrue(flow.path.isEmpty)
        XCTAssertNil(flow.round)
    }

    func testNewGameOpensSettings() {
        let flow = GameFlow()
        flow.newGame()
        XCTAssertEqual(flow.path, [.setup])
        XCTAssertNil(flow.round)
    }

    func testStartRoundBuildsARoundAndPushesIt() {
        let flow = GameFlow()
        let settings = GameSettings()
        flow.newGame()
        flow.path.append(.names)
        flow.startRound(settings: settings)

        XCTAssertEqual(flow.path, [.setup, .names, .round])
        XCTAssertNotNil(flow.round)
        XCTAssertEqual(flow.round?.players.count, settings.playerCount)
        XCTAssertEqual(flow.round?.phase, .reveal)
    }

    func testStartRoundHonoursTheDeckSelection() {
        let flow = GameFlow()
        let settings = GameSettings()
        settings.deselectAllDecks()
        settings.toggle(Decks.animals)
        for _ in 0..<100 {
            flow.startRound(settings: settings)
            XCTAssertEqual(flow.round?.category, "Animals")
        }
    }

    func testPlayAgainReturnsToSettingsAndDropsTheOldRound() {
        let flow = GameFlow()
        let settings = GameSettings()
        flow.newGame()
        flow.path.append(.names)
        flow.startRound(settings: settings)
        flow.round?.phase = .result

        flow.playAgain()
        XCTAssertEqual(flow.path, [.setup], "two levels popped, back at Game Settings")
        XCTAssertNil(flow.round, "a finished round must not leak into the next one")
    }

    func testPlayAgainKeepsTheSettingsIntact() {
        let flow = GameFlow()
        let settings = GameSettings()
        settings.setPlayerCount(7)
        settings.setName("Josh", at: 0)
        settings.imposterGetsHint = true
        flow.startRound(settings: settings)
        flow.playAgain()

        XCTAssertEqual(settings.playerCount, 7, "players carry over to the next round")
        XCTAssertEqual(settings.name(at: 0), "Josh")
        XCTAssertTrue(settings.imposterGetsHint)
    }

    func testBackToMenuClearsEverything() {
        let flow = GameFlow()
        let settings = GameSettings()
        flow.newGame()
        flow.startRound(settings: settings)
        flow.backToMenu()
        XCTAssertTrue(flow.path.isEmpty)
        XCTAssertNil(flow.round)
    }

    func testStartingASecondRoundReplacesTheFirst() {
        let flow = GameFlow()
        let settings = GameSettings()
        flow.startRound(settings: settings)
        let first = flow.round
        flow.playAgain()
        flow.startRound(settings: settings)
        XCTAssertFalse(first === flow.round, "each round is a fresh object")
    }
}
