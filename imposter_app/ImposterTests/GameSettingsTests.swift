import XCTest
@testable import Imposter

final class GameSettingsTests: XCTestCase {

    // MARK: - Defaults

    func testDefaultsMatchTheGameAsMostPeoplePlayIt() {
        let s = GameSettings()
        XCTAssertEqual(s.playerCount, 4)
        XCTAssertEqual(s.playerNames.count, 4)
        XCTAssertEqual(s.imposterCount, 1)
        XCTAssertEqual(s.imposterMode, .fixed)
        XCTAssertFalse(s.imposterGetsHint, "hints are opt-in; the imposter gets the category alone")
        XCTAssertFalse(s.impostersKnowEachOther, "blind imposters are the default")
        XCTAssertFalse(s.imposterNeverGoesFirst)
    }

    // MARK: - Player count

    func testPlayerCountClampsToRange() {
        let s = GameSettings()
        s.setPlayerCount(1)
        XCTAssertEqual(s.playerCount, 3, "3 is the floor")
        s.setPlayerCount(500)
        XCTAssertEqual(s.playerCount, 100, "100 is the ceiling")
        XCTAssertEqual(s.playerNames.count, 100)
    }

    func testGrowingKeepsNamesAlreadyTyped() {
        let s = GameSettings()
        s.setName("Josh", at: 0)
        s.setName("Alan", at: 1)
        s.setPlayerCount(6)
        XCTAssertEqual(s.name(at: 0), "Josh")
        XCTAssertEqual(s.name(at: 1), "Alan")
        XCTAssertEqual(s.name(at: 4), "Player 5", "new slots get placeholders")
        XCTAssertEqual(s.playerNames.count, 6)
    }

    func testShrinkingTrimsNamesToCount() {
        let s = GameSettings()
        s.setPlayerCount(8)
        s.setPlayerCount(3)
        XCTAssertEqual(s.playerNames.count, 3)
        XCTAssertEqual(s.playerCount, 3)
    }

    func testAddAndRemovePlayerStepOneAtATime() {
        let s = GameSettings()
        s.addPlayer()
        XCTAssertEqual(s.playerCount, 5)
        s.removePlayer()
        XCTAssertEqual(s.playerCount, 4)
    }

    func testRemovingAtIndexDropsThatPersonSpecifically() {
        let s = GameSettings()
        s.playerNames = ["Josh", "Alan", "Logan", "Sarah"]
        s.removePlayer(at: 1)
        XCTAssertEqual(s.playerNames, ["Josh", "Logan", "Sarah"])
        XCTAssertEqual(s.playerCount, 3, "count follows the names array")
    }

    func testRemovingAtIndexRefusesToGoBelowTheMinimum() {
        let s = GameSettings()
        s.setPlayerCount(3)
        s.removePlayer(at: 0)
        XCTAssertEqual(s.playerCount, 3, "a 3-player game cannot shed another player")
        XCTAssertEqual(s.playerNames.count, 3)
    }

    func testOutOfBoundsNameAccessIsSafe() {
        let s = GameSettings()
        XCTAssertEqual(s.name(at: 99), "", "a stale index during a removal animation must not trap")
        s.setName("Ghost", at: 99)
        XCTAssertEqual(s.playerNames.count, 4, "writing out of bounds is a no-op")
    }

    // MARK: - Imposter cap

    func testBlindImpostersCanBeAlmostEveryone() {
        let s = GameSettings()
        s.setPlayerCount(10)
        XCTAssertFalse(s.impostersKnowEachOther)
        XCTAssertEqual(s.imposterCap, 9, "blind imposters cannot collude, so n-1 is allowed")
        XCTAssertEqual(s.imposterRange, 1...9)
    }

    func testImpostersWhoKnowEachOtherAreHeldToHalfTheTable() {
        let s = GameSettings()
        s.setPlayerCount(10)
        s.setImpostersKnowEachOther(true)
        XCTAssertEqual(s.imposterCap, 5, "coordinating imposters are capped at n/2")
    }

    func testCapNeverDropsBelowOne() {
        let s = GameSettings()
        s.setPlayerCount(3)
        s.setImpostersKnowEachOther(true)
        XCTAssertEqual(s.imposterCap, 1, "3/2 == 1, and a round always needs one imposter")
    }

    func testTurningOnTeammateKnowledgeReclampsTheCount() {
        let s = GameSettings()
        s.setPlayerCount(10)
        s.setImposterCount(9)
        XCTAssertEqual(s.imposterCount, 9)
        s.setImpostersKnowEachOther(true)
        XCTAssertEqual(s.imposterCount, 5, "the cap tightened, so the count had to come down")
    }

    func testShrinkingTheTableReclampsTheImposterCount() {
        let s = GameSettings()
        s.setPlayerCount(10)
        s.setImposterCount(8)
        s.setPlayerCount(4)
        XCTAssertLessThanOrEqual(s.imposterCount, s.imposterCap)
        XCTAssertEqual(s.imposterCount, 3, "4 blind players cap at 3")
    }

    func testImposterCountClampsAtBothEnds() {
        let s = GameSettings()
        s.setPlayerCount(6)
        s.setImposterCount(0)
        XCTAssertEqual(s.imposterCount, 1)
        s.setImposterCount(99)
        XCTAssertEqual(s.imposterCount, 5)
    }

    func testRecommendedIsRoughlyOnePerFourAndAlwaysLegal() {
        let s = GameSettings()
        for n in GameSettings.playerRange {
            s.setPlayerCount(n)
            let r = s.recommendedImposters
            XCTAssertTrue(s.imposterRange.contains(r), "recommendation out of range at \(n) players")
        }
        s.setPlayerCount(4);  XCTAssertEqual(s.recommendedImposters, 1)
        s.setPlayerCount(8);  XCTAssertEqual(s.recommendedImposters, 2)
        s.setPlayerCount(12); XCTAssertEqual(s.recommendedImposters, 3)
    }

    func testSummaryHidesTheCountInRandomMode() {
        let s = GameSettings()
        XCTAssertEqual(s.imposterSummary, "1")
        s.imposterMode = .random
        XCTAssertEqual(s.imposterSummary, "?", "the group must not be told how many")
    }

    // MARK: - Deck selection

    func testEveryDeckIsOnToStart() {
        let s = GameSettings()
        XCTAssertEqual(s.selectedDecks.count, Decks.all.count)
        XCTAssertTrue(s.canStart)
        XCTAssertEqual(s.deckSummary, "All 3 decks")
        XCTAssertEqual(s.selectedCardCount, 300)
    }

    func testTogglingADeckOffRemovesItFromPlay() {
        let s = GameSettings()
        s.toggle(Decks.animals)
        XCTAssertFalse(s.isSelected(Decks.animals))
        XCTAssertEqual(s.selectedDecks.count, 2)
        XCTAssertEqual(s.deckSummary, "2 of 3 decks")
        XCTAssertEqual(s.selectedCardCount, 200)
    }

    func testTogglingIsItsOwnInverse() {
        let s = GameSettings()
        let before = s.selectedDeckIDs
        s.toggle(Decks.sports)
        s.toggle(Decks.sports)
        XCTAssertEqual(s.selectedDeckIDs, before)
    }

    func testSingleDeckSummaryNamesIt() {
        let s = GameSettings()
        s.deselectAllDecks()
        s.toggle(Decks.sports)
        XCTAssertEqual(s.deckSummary, "Sports")
    }

    func testDeselectAllBlocksStarting() {
        let s = GameSettings()
        s.deselectAllDecks()
        XCTAssertFalse(s.canStart, "a round needs somewhere to draw a word from")
        XCTAssertEqual(s.deckSummary, "None selected")
        XCTAssertEqual(s.selectedCardCount, 0)
    }

    func testSelectAllRestoresEverything() {
        let s = GameSettings()
        s.deselectAllDecks()
        s.selectAllDecks()
        XCTAssertEqual(s.selectedDecks.count, Decks.all.count)
        XCTAssertTrue(s.canStart)
    }

    func testRandomDeckNeverReturnsADeselectedDeck() {
        let s = GameSettings()
        s.toggle(Decks.animals)
        s.toggle(Decks.foods)
        for _ in 0..<500 {
            XCTAssertEqual(s.randomDeck().id, "sports")
        }
    }

    func testRandomDeckFallsBackRatherThanTrapping() {
        let s = GameSettings()
        s.deselectAllDecks()
        let deck = s.randomDeck()
        XCTAssertTrue(Decks.all.contains { $0.id == deck.id },
                      "an empty selection must not crash a round")
    }
}
