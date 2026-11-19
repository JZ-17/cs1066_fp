import Foundation
import Observation
import Supabase

/// Every deck the game can draw from: the three built in ones, plus whatever
/// this player has made.
///
/// Read offline, write online for creation. Creating a deck needs the network
/// anyway, because the words come from a model. Renames, deletes and card
/// edits can be queued and replayed, which is safe here because an anonymous
/// account only ever lives on one phone, so no two devices can edit the same
/// row and there is nothing to reconcile.
@Observable
final class DeckLibrary {

    enum Status: Equatable {
        case idle
        case loading
        /// Fetched from the server just now.
        case live
        /// Showing the cache because the server could not be reached.
        case offline
        /// Reached the server and it said no.
        case failed(String)
    }

    /// Matches the trigger in the migration. Shown in the UI before a player
    /// spends a generation they will not be allowed to save.
    static let deckLimit = 50

    private(set) var stored: [StoredDeck] = []
    private(set) var status: Status = .idle
    private(set) var lastUpdated: Date?

    /// What the deck picker lists and what a round draws from.
    var custom: [Deck] { stored.map(\.asDeck) }
    var all: [Deck] { Decks.all + custom }

    var isAtLimit: Bool { stored.count >= Self.deckLimit }
    var remainingSlots: Int { max(0, Self.deckLimit - stored.count) }

    private let cache = DeckCache()
    private let client: SupabaseClient?

    init() {
        client = SupabaseConfig.isConfigured
            ? SupabaseClient(
                supabaseURL: SupabaseConfig.url,
                supabaseKey: SupabaseConfig.publishableKey
              )
            : nil
    }

    // MARK: Loading

    /// Call once at launch.
    ///
    /// The cache is read first, so the deck picker has something to draw
    /// immediately instead of a spinner. The refresh then tops it up.
    @MainActor
    func start() async {
        stored = cache.load()
        lastUpdated = cache.savedAt()
        if !stored.isEmpty { status = .offline }
        await refresh()
    }

    /// Pulls down only what changed.
    ///
    /// Two queries at most, and on a launch where nothing has changed it is one
    /// small one. Asking for every deck with every card would mean a few
    /// thousand rows on every launch to learn that nothing happened.
    ///
    ///  1. the deck list, without cards. Fifty short rows.
    ///  2. the cards of only those decks whose updated_at moved, in one `in`
    ///     query rather than one request per deck.
    ///
    /// Decks missing from step 1 were deleted elsewhere, so they are dropped.
    /// That is why no tombstone table is needed.
    @MainActor
    func refresh() async {
        guard let client else {
            // No key set yet. The three built in decks still work.
            status = .idle
            return
        }

        status = .loading
        do {
            try await signInIfNeeded(client)

            let summaries: [StoredDeck] = try await client
                .from("decks")
                .select("id,name,symbol,topic,updated_at")
                .order("updated_at", ascending: false)
                .execute()
                .value

            let cached = Dictionary(uniqueKeysWithValues: stored.map { ($0.id, $0) })

            // A deck needs its cards if we have never had them, or if the
            // server says it moved since we last looked.
            let staleIDs = summaries
                .filter { summary in
                    guard let known = cached[summary.id], !known.cards.isEmpty else { return true }
                    return summary.updatedAt > known.updatedAt
                }
                .map(\.id)

            var cardsByDeck: [UUID: [StoredCard]] = [:]
            if !staleIDs.isEmpty {
                let rows: [CardRow] = try await client
                    .from("cards")
                    .select("id,deck_id,word,hints,position")
                    .in("deck_id", values: staleIDs.map(\.uuidString))
                    .execute()
                    .value
                cardsByDeck = Dictionary(grouping: rows, by: \.deckID)
                    .mapValues { $0.map(\.asStoredCard) }
            }

            stored = summaries.map { summary in
                var deck = summary
                deck.cards = cardsByDeck[summary.id] ?? cached[summary.id]?.cards ?? []
                return deck
            }

            cache.save(stored)
            lastUpdated = Date()
            status = .live
        } catch {
            // Keep whatever the cache gave us. A failed refresh must never
            // empty a list the player is looking at.
            status = stored.isEmpty ? .failed(Self.describe(error)) : .offline
        }
    }

    // MARK: Writing
    //
    // Online only for now. Each edit changes the local copy first so the
    // screen reacts at once, then sends it. If the send fails the local copy
    // is put back, because showing a rename that did not happen is worse than
    // showing an error.

    enum WriteError: LocalizedError {
        case offline
        case badHints(String)
        case server(String)

        var errorDescription: String? {
            switch self {
            case .offline:            "You need a connection for this."
            case .badHints(let why):  why
            case .server(let why):    why
            }
        }
    }

    @MainActor
    func rename(deckID: UUID, to newName: String) async throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 60 else {
            throw WriteError.badHints("A deck name has to be 1 to 60 characters.")
        }
        guard let client else { throw WriteError.offline }
        guard let index = stored.firstIndex(where: { $0.id == deckID }) else { return }

        let previous = stored[index]
        stored[index].name = trimmed

        do {
            try await client.from("decks")
                .update(["name": trimmed])
                .eq("id", value: deckID.uuidString)
                .execute()
            cache.save(stored)
        } catch {
            stored[index] = previous
            throw WriteError.server(Self.describe(error))
        }
    }

    @MainActor
    func deleteDeck(_ deckID: UUID) async throws {
        guard let client else { throw WriteError.offline }
        guard let index = stored.firstIndex(where: { $0.id == deckID }) else { return }

        let previous = stored
        stored.remove(at: index)

        do {
            // The cards go too, by the cascade on the foreign key.
            try await client.from("decks")
                .delete()
                .eq("id", value: deckID.uuidString)
                .execute()
            cache.save(stored)
        } catch {
            stored = previous
            throw WriteError.server(Self.describe(error))
        }
    }

    @MainActor
    func updateCard(_ card: StoredCard, in deckID: UUID) async throws {
        if let complaint = Self.problemWithHints(card.hints) {
            throw WriteError.badHints(complaint)
        }
        let word = card.word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { throw WriteError.badHints("A card needs a word.") }

        guard let client else { throw WriteError.offline }
        guard let deckIndex = stored.firstIndex(where: { $0.id == deckID }),
              let cardIndex = stored[deckIndex].cards.firstIndex(where: { $0.id == card.id })
        else { return }

        let previous = stored[deckIndex].cards[cardIndex]
        var edited = card
        edited.word = word
        edited.hints = card.hints.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        stored[deckIndex].cards[cardIndex] = edited

        do {
            try await client.from("cards")
                .update(CardPatch(word: edited.word, hints: edited.hints))
                .eq("id", value: card.id.uuidString)
                .execute()
            cache.save(stored)
        } catch {
            stored[deckIndex].cards[cardIndex] = previous
            throw WriteError.server(Self.describe(error))
        }
    }

    @MainActor
    func deleteCard(_ cardID: UUID, from deckID: UUID) async throws {
        guard let client else { throw WriteError.offline }
        guard let deckIndex = stored.firstIndex(where: { $0.id == deckID }) else { return }

        let previous = stored[deckIndex].cards
        stored[deckIndex].cards.removeAll { $0.id == cardID }

        do {
            try await client.from("cards")
                .delete()
                .eq("id", value: cardID.uuidString)
                .execute()
            cache.save(stored)
        } catch {
            stored[deckIndex].cards = previous
            throw WriteError.server(Self.describe(error))
        }
    }

    /// Mirrors the valid_hints check in the database.
    ///
    /// Checking here as well is not duplication for its own sake. The database
    /// is what actually enforces it, but a 400 from Postgres is no use to a
    /// player. This turns the same rule into a sentence they can act on.
    static func problemWithHints(_ hints: [String]) -> String? {
        guard hints.count == 5 else {
            return "A card needs exactly 5 hints. This one has \(hints.count)."
        }
        let blanks = hints.filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard blanks.isEmpty else {
            return blanks.count == 1 ? "One hint is empty." : "\(blanks.count) hints are empty."
        }
        return nil
    }

    // MARK: Session

    /// Signs in anonymously the first time, then reuses that session.
    ///
    /// The player never sees this. The SDK keeps the session in the keychain,
    /// which tends to outlive the app being deleted, so a reinstall often lands
    /// back on the same account with the same decks.
    private func signInIfNeeded(_ client: SupabaseClient) async throws {
        if (try? await client.auth.session) != nil { return }
        _ = try await client.auth.signInAnonymously()
    }

    private static func describe(_ error: Error) -> String {
        guard let urlError = error as? URLError else { return error.localizedDescription }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return "No connection."
        case .timedOut:
            return "The server took too long."
        default:
            return "Could not reach the server."
        }
    }
}

/// The columns a card edit writes. A struct rather than a dictionary, because
/// a dictionary holding both a string and an array of strings has no single
/// value type the encoder will accept.
private struct CardPatch: Encodable {
    let word: String
    let hints: [String]
}

// MARK: - Rows as the cards query returns them

/// `cards` rows carry their deck id so one query can cover many decks. The
/// game model has no use for that, so it is dropped on the way in.
private struct CardRow: Decodable {
    let id: UUID
    let deckID: UUID
    let word: String
    let hints: [String]
    let position: Int

    enum CodingKeys: String, CodingKey {
        case id, word, hints, position
        case deckID = "deck_id"
    }

    var asStoredCard: StoredCard {
        StoredCard(id: id, word: word, hints: hints, position: position)
    }
}
