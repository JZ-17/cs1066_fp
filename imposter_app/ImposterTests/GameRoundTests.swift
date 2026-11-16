import XCTest
@testable import Imposter

final class GameRoundTests: XCTestCase {

    /// Rounds are built from shuffles, so most of these run many trials and
    /// assert an invariant rather than one expected value.
    private func makeSettings(
        players: Int = 6,
        imposters: Int = 2,
        hints: Bool = false,
        knowEachOther: Bool = false,
        neverFirst: Bool = false,
        mode: ImposterMode = .fixed
    ) -> GameSettings {
        let s = GameSettings()
        s.setPlayerCount(players)
        s.imposterGetsHint = hints
        s.setImpostersKnowEachOther(knowEachOther)
        s.imposterNeverGoesFirst = neverFirst
        s.imposterMode = mode
        s.setImposterCount(imposters)
        return s
    }

    // MARK: - What each player sees

    func testInnocentsSeeTheWordAndImpostersSeeTheCategory() {
        for _ in 0..<200 {
            let r = GameRound(settings: makeSettings(), deck: Decks.animals)
            for i in r.players.indices {
                if r.isImposter(i) {
                    XCTAssertEqual(r.secret(for: i), "Animals")
                    XCTAssertEqual(r.secretLabel(for: i), "YOUR CATEGORY")
                } else {
                    XCTAssertEqual(r.secret(for: i), r.card.word)
                    XCTAssertEqual(r.secretLabel(for: i), "THE WORD")
                }
            }
        }
    }

    func testCategoryModeAssignsNoHintsAtAll() {
        for _ in 0..<100 {
            let r = GameRound(settings: makeSettings(hints: false), deck: Decks.foods)
            XCTAssertTrue(r.hints.isEmpty)
            for i in r.imposters {
                XCTAssertEqual(r.revealedHint(for: i), "", "nothing to reveal later either")
            }
        }
    }

    func testHintModeDrawsFromTheCardAndNeverLeaksTheWord() {
        for _ in 0..<200 {
            let r = GameRound(settings: makeSettings(hints: true), deck: Decks.foods)
            XCTAssertEqual(r.hints.count, 2)
            for i in r.imposters {
                let hint = r.secret(for: i)
                XCTAssertTrue(r.card.hints.contains(hint), "\(hint) is not one of this card's hints")
                XCTAssertNotEqual(hint, r.card.word)
                XCTAssertNotEqual(hint, r.category, "hint mode must not fall back to the category")
                XCTAssertEqual(r.secretLabel(for: i), "YOUR HINT")
            }
        }
    }

    func testTwoImpostersNeverGetTheSameHint() {
        for _ in 0..<300 {
            let r = GameRound(settings: makeSettings(hints: true), deck: Decks.sports)
            let given = r.imposters.map { r.secret(for: $0) }
            XCTAssertEqual(Set(given).count, given.count,
                           "matching clues would give the pair away: \(given)")
        }
    }

    func testHintPoolRecyclesWhenImpostersOutnumberHints() {
        // 11 imposters, 5 hints per card: the pool has to refill without crashing.
        let r = GameRound(settings: makeSettings(players: 12, imposters: 11, hints: true),
                          deck: Decks.foods)
        XCTAssertEqual(r.hints.count, 11)
        for i in r.imposters {
            XCTAssertTrue(r.card.hints.contains(r.secret(for: i)))
        }
    }

    func testImposterNoteChangesWithTheMode() {
        let blind = GameRound(settings: makeSettings(imposters: 1, hints: false), deck: Decks.animals)
        let hinted = GameRound(settings: makeSettings(imposters: 1, hints: true), deck: Decks.animals)
        let b = blind.imposterNote(for: blind.imposters.first!)
        let h = hinted.imposterNote(for: hinted.imposters.first!)
        XCTAssertTrue(b.contains("category"), b)
        XCTAssertNotEqual(b, h)
    }

    // MARK: - Who the imposters are

    func testFixedModeProducesExactlyThatManyImposters() {
        for count in 1...5 {
            for _ in 0..<50 {
                let r = GameRound(settings: makeSettings(players: 6, imposters: count), deck: Decks.foods)
                XCTAssertEqual(r.imposters.count, count)
            }
        }
    }

    func testRandomModeStaysInsideTheLegalRange() {
        let s = makeSettings(players: 8, imposters: 1, mode: .random)
        for _ in 0..<300 {
            let r = GameRound(settings: s, deck: Decks.foods)
            XCTAssertTrue(s.imposterRange.contains(r.imposters.count))
            XCTAssertTrue(r.imposterCountIsSecret)
        }
    }

    func testImposterIndicesAreAlwaysRealPlayers() {
        for _ in 0..<200 {
            let r = GameRound(settings: makeSettings(), deck: Decks.sports)
            for i in r.imposters {
                XCTAssertTrue(r.players.indices.contains(i))
            }
        }
    }

    func testRoundUsesOnlyTheFirstNNames() {
        let s = makeSettings(players: 4, imposters: 1)
        s.playerNames = ["A", "B", "C", "D", "E", "F"]   // stale extras
        let r = GameRound(settings: s, deck: Decks.foods)
        XCTAssertEqual(r.players, ["A", "B", "C", "D"])
    }

    // MARK: - Turn order

    func testTurnOrderIsEveryPlayerExactlyOnce() {
        for _ in 0..<200 {
            let r = GameRound(settings: makeSettings(), deck: Decks.foods)
            XCTAssertEqual(Set(r.turnOrder), Set(r.players.indices))
            XCTAssertEqual(r.turnOrder.count, r.players.count)
        }
    }

    func testImposterNeverGoesFirstWhenTheSettingIsOn() {
        for _ in 0..<400 {
            let r = GameRound(settings: makeSettings(neverFirst: true), deck: Decks.foods)
            XCTAssertFalse(r.isImposter(r.turnOrder[0]), "\(r.leadPlayer) led but was an imposter")
        }
    }

    func testImposterNeverGoesFirstHoldsEvenWithOnlyOneInnocent() {
        for _ in 0..<200 {
            let r = GameRound(settings: makeSettings(players: 5, imposters: 4, neverFirst: true),
                              deck: Decks.foods)
            XCTAssertFalse(r.isImposter(r.turnOrder[0]),
                           "the single innocent must be pulled to the front")
        }
    }

    func testImposterCanLeadWhenTheSettingIsOff() {
        var sawImposterLead = false
        for _ in 0..<300 where !sawImposterLead {
            let r = GameRound(settings: makeSettings(neverFirst: false), deck: Decks.foods)
            if r.isImposter(r.turnOrder[0]) { sawImposterLead = true }
        }
        XCTAssertTrue(sawImposterLead, "with the setting off, order should be a plain shuffle")
    }

    // MARK: - Teammates

    func testBlindImpostersAreToldNothingAboutEachOther() {
        for _ in 0..<200 {
            let r = GameRound(settings: makeSettings(knowEachOther: false), deck: Decks.foods)
            for i in r.players.indices {
                XCTAssertTrue(r.teammates(of: i).isEmpty)
            }
        }
    }

    func testKnownImpostersSeeEachOtherButNotThemselves() {
        for _ in 0..<200 {
            let r = GameRound(settings: makeSettings(players: 8, imposters: 3, knowEachOther: true),
                              deck: Decks.foods)
            for i in r.imposters {
                let mates = r.teammates(of: i)
                XCTAssertEqual(mates.count, r.imposters.count - 1)
                XCTAssertFalse(mates.contains(r.players[i]), "an imposter is not their own teammate")
            }
        }
    }

    func testInnocentsNeverSeeATeammateListEvenWhenImpostersKnow() {
        for _ in 0..<200 {
            let r = GameRound(settings: makeSettings(knowEachOther: true), deck: Decks.foods)
            for i in r.players.indices where !r.isImposter(i) {
                XCTAssertTrue(r.teammates(of: i).isEmpty)
            }
        }
    }

    // MARK: - Briefing

    func testBriefingNamesTheDeckAndTheLeadPlayer() {
        let r = GameRound(settings: makeSettings(), deck: Decks.animals)
        let text = r.briefing.joined(separator: " ")
        XCTAssertTrue(text.contains("Animals"))
        XCTAssertTrue(text.contains(r.leadPlayer))
    }

    func testBriefingTellsTheGroupWhetherHintsWereGiven() {
        let blind = GameRound(settings: makeSettings(hints: false), deck: Decks.sports)
            .briefing.joined(separator: " ")
        let hinted = GameRound(settings: makeSettings(hints: true), deck: Decks.sports)
            .briefing.joined(separator: " ")
        XCTAssertTrue(blind.contains("all the imposters know"), blind)
        XCTAssertTrue(hinted.contains("hint word"), hinted)
    }

    func testBriefingStatesTheImposterCountUnlessItIsSecret() {
        let one = GameRound(settings: makeSettings(imposters: 1), deck: Decks.foods)
            .briefing.joined(separator: " ")
        XCTAssertTrue(one.contains("exactly one imposter"), one)

        let two = GameRound(settings: makeSettings(imposters: 2), deck: Decks.foods)
            .briefing.joined(separator: " ")
        XCTAssertTrue(two.contains("2 imposters"), two)

        let secret = GameRound(settings: makeSettings(mode: .random), deck: Decks.foods)
            .briefing.joined(separator: " ")
        XCTAssertTrue(secret.contains("random this round"), secret)
        XCTAssertFalse(secret.contains("exactly one imposter"), "the count must stay hidden")
    }

    func testBriefingMentionsTheLeadGuaranteeOnlyWhenItApplies() {
        let on = GameRound(settings: makeSettings(neverFirst: true), deck: Decks.foods)
        XCTAssertTrue(on.briefing.joined().contains("never goes first"))

        let off = GameRound(settings: makeSettings(neverFirst: false), deck: Decks.foods)
        XCTAssertFalse(off.briefing.joined().contains("never goes first"))
    }

    // MARK: - Phases

    func testRoundStartsOnTheRevealPhase() {
        let r = GameRound(settings: makeSettings(), deck: Decks.foods)
        XCTAssertEqual(r.phase, .reveal)
        XCTAssertEqual(r.revealIndex, 0)
    }

    func testAdvanceRevealWalksEveryPlayerThenMovesToClues() {
        let r = GameRound(settings: makeSettings(players: 5, imposters: 1), deck: Decks.foods)
        for expected in 0..<4 {
            XCTAssertEqual(r.revealPlayer, expected)
            XCTAssertEqual(r.phase, .reveal)
            XCTAssertFalse(r.isLastReveal)
            r.advanceReveal()
        }
        XCTAssertEqual(r.revealPlayer, 4)
        XCTAssertTrue(r.isLastReveal)
        r.advanceReveal()
        XCTAssertEqual(r.phase, .clues, "after the last player the group starts giving clues")
    }

    func testRevealAnswerEndsTheRound() {
        let r = GameRound(settings: makeSettings(), deck: Decks.foods)
        r.phase = .clues
        r.revealAnswer()
        XCTAssertEqual(r.phase, .result)
    }
}
