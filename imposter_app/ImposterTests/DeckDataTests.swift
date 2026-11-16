import XCTest
@testable import Imposter

/// Guards the deck data itself. These are the regression tests for the hint
/// rules: one or two lowercase words, associative rather than descriptive, and
/// never a giveaway. A machine can only check the mechanical half of that.
/// The judgement half needs a person or the generator's scorer. So these
/// catch the failures that *are* mechanical and leave the rest documented.
final class DeckDataTests: XCTestCase {

    func testThreeDecksShip() {
        XCTAssertEqual(Decks.all.count, 3)
        XCTAssertEqual(Set(Decks.all.map(\.id)).count, 3, "deck ids must be unique")
    }

    func testDeckMetadataIsPresent() {
        for deck in Decks.all {
            XCTAssertFalse(deck.id.isEmpty)
            XCTAssertFalse(deck.name.isEmpty)
            XCTAssertFalse(deck.symbol.isEmpty)
        }
    }

    func testEveryDeckHasOneHundredCards() {
        for deck in Decks.all {
            XCTAssertEqual(deck.cards.count, 100, "\(deck.name) has \(deck.cards.count) cards")
        }
    }

    func testEveryCardHasFiveHints() {
        for deck in Decks.all {
            for card in deck.cards {
                XCTAssertEqual(card.hints.count, 5, "\(deck.name)/\(card.word)")
            }
        }
    }

    func testWordsAreNotEmptyAndUniqueWithinADeck() {
        for deck in Decks.all {
            var seen = Set<String>()
            for card in deck.cards {
                XCTAssertFalse(card.word.isEmpty, "\(deck.name) has an empty word")
                XCTAssertTrue(seen.insert(card.word.lowercased()).inserted,
                              "\(deck.name) repeats \(card.word)")
            }
        }
    }

    func testHintsAreOneOrTwoLowercaseWords() {
        for deck in Decks.all {
            for card in deck.cards {
                for hint in card.hints {
                    XCTAssertFalse(hint.isEmpty, "\(deck.name)/\(card.word) has an empty hint")
                    XCTAssertEqual(hint, hint.lowercased(),
                                   "\(deck.name)/\(card.word): \"\(hint)\" is not lowercase")
                    XCTAssertLessThanOrEqual(
                        hint.split(separator: " ").count, 2,
                        "\(deck.name)/\(card.word): \"\(hint)\" is longer than two words"
                    )
                    XCTAssertFalse(hint.hasPrefix(" ") || hint.hasSuffix(" "),
                                   "\(deck.name)/\(card.word): \"\(hint)\" has stray whitespace")
                }
            }
        }
    }

    func testACardNeverRepeatsAHint() {
        for deck in Decks.all {
            for card in deck.cards {
                XCTAssertEqual(Set(card.hints).count, card.hints.count,
                               "\(deck.name)/\(card.word) repeats a hint: \(card.hints)")
            }
        }
    }

    /// The flat giveaway: a hint that contains the answer, or is contained by
    /// it. "rings" for Onion Rings hands the imposter the final guess.
    func testNoHintOverlapsItsOwnWord() {
        for deck in Decks.all {
            for card in deck.cards {
                let word = card.word.lowercased()
                for hint in card.hints {
                    let h = hint.lowercased()
                    XCTAssertFalse(word.contains(h),
                                   "\(deck.name)/\(card.word): \"\(hint)\" is part of the answer")
                    XCTAssertFalse(h.contains(word),
                                   "\(deck.name)/\(card.word): \"\(hint)\" contains the answer")
                }
            }
        }
    }

    /// Ambiguity is the point, so a hint shared across cards is good. A hint
    /// unique to one card in a 100-card deck is the "Messi" failure. It
    /// points at exactly one answer. This is a soft signal, so the bar is
    /// deliberately loose: it only fires if a deck has almost no overlap at
    /// all, which would mean the ambiguity rule was abandoned wholesale.
    func testDecksReuseHintsAcrossCards() {
        for deck in Decks.all {
            var tally: [String: Int] = [:]
            for card in deck.cards {
                for hint in card.hints { tally[hint, default: 0] += 1 }
            }
            let shared = tally.values.filter { $0 > 1 }.count
            XCTAssertGreaterThan(shared, 20,
                "\(deck.name) only shares \(shared) hints between cards; hints look too specific")
        }
    }

    func testEveryCardCanSupplyDistinctHintsToTwoImposters() {
        for deck in Decks.all {
            for card in deck.cards {
                XCTAssertGreaterThanOrEqual(Set(card.hints).count, 2,
                    "\(deck.name)/\(card.word) cannot give two imposters different hints")
            }
        }
    }
}
