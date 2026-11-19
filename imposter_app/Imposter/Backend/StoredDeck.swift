import Foundation

/// A custom deck as it exists in the database and in the cache.
///
/// The game plays with `Deck` and `Card`, which hold nothing but the words.
/// This type is the same deck with its database identity attached. Keeping
/// them apart means the three built in decks never have to carry a row id they
/// would have no use for, and the 300 cards compiled into the app stay as
/// plain `Card(word:hints:)`.
///
/// Ids are generated on the phone, not by Postgres. That is what lets an edit
/// made with no signal name the row it is going to change once the connection
/// comes back.
struct StoredDeck: Codable, Identifiable, Hashable {

    let id: UUID
    var name: String
    var symbol: String
    var topic: String?

    /// The sync watermark. The server bumps this whenever the deck or any of
    /// its cards changes, so the phone can ask for only what it is missing.
    var updatedAt: Date

    /// Empty until the cards have been fetched. The deck list query leaves
    /// them out on purpose, because a list of fifty names should not drag a
    /// few thousand cards along with it.
    var cards: [StoredCard]

    enum CodingKeys: String, CodingKey {
        case id, name, symbol, topic, cards
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String = "🃏",
        topic: String? = nil,
        updatedAt: Date = Date(),
        cards: [StoredCard] = []
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.topic = topic
        self.updatedAt = updatedAt
        self.cards = cards
    }

    /// Decks arriving from the deck list query carry no cards, so default them
    /// rather than failing to decode.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        symbol = try c.decode(String.self, forKey: .symbol)
        topic = try c.decodeIfPresent(String.self, forKey: .topic)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        cards = try c.decodeIfPresent([StoredCard].self, forKey: .cards) ?? []
    }

    /// The form the game actually plays with.
    var asDeck: Deck {
        Deck(
            id: id.uuidString,
            name: name,
            symbol: symbol,
            // Postgres returns rows in no promised order, so sort before play.
            cards: cards.sorted { $0.position < $1.position }.map(\.asCard)
        )
    }
}

struct StoredCard: Codable, Identifiable, Hashable {

    let id: UUID
    var word: String
    var hints: [String]

    /// Keeps the deck in the order it was generated.
    var position: Int

    enum CodingKeys: String, CodingKey {
        case id, word, hints, position
    }

    init(id: UUID = UUID(), word: String, hints: [String], position: Int) {
        self.id = id
        self.word = word
        self.hints = hints
        self.position = position
    }

    var asCard: Card { Card(word: word, hints: hints) }
}
