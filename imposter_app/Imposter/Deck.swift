import Foundation

/// One row of a deck: the secret word plus the hints an imposter may be given.
///
/// Hints follow the calibration rule from the generator — one or two words,
/// associated with the answer rather than describing it, and ambiguous enough
/// that hearing one alone should not identify the word.
struct Card: Hashable {
    let word: String
    let hints: [String]
}

struct Deck: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let cards: [Card]
}

/// The decks that ship with the app. These are the hand-written collections
/// from task 2 of the decomposition, reviewed by hand rather than generated.
/// Each deck lives in its own file: `DeckFoods`, `DeckSports`, `DeckAnimals`.
enum Decks {
    static let all: [Deck] = [foods, sports, animals]
}
