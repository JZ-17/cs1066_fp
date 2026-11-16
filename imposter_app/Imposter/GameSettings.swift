import Foundation
import Observation

/// How the number of imposters is decided for a round.
enum ImposterMode: Hashable {
    case fixed
    case random
}

/// Everything the setup screens configure, shared down the navigation stack.
///
/// Note: no `didSet` observers here. The `@Observable` macro turns stored
/// properties into computed ones, so assigning to a property inside its own
/// `didSet` re-enters the setter and recurses until the stack overflows.
/// All the clamping happens in explicit methods instead.
@Observable
final class GameSettings {

    static let playerRange = 3...100

    private(set) var playerCount: Int = 4
    var playerNames: [String] = (1...4).map { "Player \($0)" }

    var imposterMode: ImposterMode = .fixed
    private(set) var imposterCount: Int = 1
    var imposterNeverGoesFirst: Bool = false

    /// Off by default: the imposter is given only the deck category, which is
    /// the game as most people play it. On, they also draw one of the card's
    /// five hints at random, which makes the imposter's job markedly easier.
    var imposterGetsHint: Bool = false

    /// With several imposters, whether each is told who the others are.
    /// Off by default: blind imposters often expose themselves by accusing a
    /// teammate, which plays better than letting them coordinate.
    private(set) var impostersKnowEachOther: Bool = false

    /// Blind imposters cannot collude, so almost everyone can be one — at the
    /// limit a single innocent holds the word. Imposters who know each other
    /// can coordinate, so they are held to half the table.
    var imposterRange: ClosedRange<Int> {
        1...imposterCap
    }

    var imposterCap: Int {
        impostersKnowEachOther
            ? max(1, playerCount / 2)
            : max(1, playerCount - 1)
    }

    /// Roughly one imposter per four players, which is how the game plays best.
    var recommendedImposters: Int {
        max(1, Int((Double(playerCount) / 4).rounded())).clamped(to: imposterRange)
    }

    /// What the summary card shows: a number, or a dash when it varies.
    var imposterSummary: String {
        imposterMode == .random ? "?" : "\(imposterCount)"
    }

    // MARK: Decks

    /// Which decks a round may draw its word from. Everything is on to start.
    /// Stored as ids rather than `Deck` values so the set survives a deck list
    /// that grows later.
    private(set) var selectedDeckIDs: Set<String> = Set(Decks.all.map(\.id))

    var selectedDecks: [Deck] {
        Decks.all.filter { selectedDeckIDs.contains($0.id) }
    }

    /// Deselecting every deck is allowed — there is a Deselect All button —
    /// so the start button has to be able to refuse.
    var canStart: Bool { !selectedDecks.isEmpty }

    var deckSummary: String {
        let chosen = selectedDecks
        if chosen.isEmpty { return "None selected" }
        if chosen.count == Decks.all.count { return "All \(chosen.count) decks" }
        if chosen.count == 1 { return chosen[0].name }
        return "\(chosen.count) of \(Decks.all.count) decks"
    }

    var selectedCardCount: Int {
        selectedDecks.reduce(0) { $0 + $1.cards.count }
    }

    func isSelected(_ deck: Deck) -> Bool { selectedDeckIDs.contains(deck.id) }

    func toggle(_ deck: Deck) {
        if selectedDeckIDs.contains(deck.id) {
            selectedDeckIDs.remove(deck.id)
        } else {
            selectedDeckIDs.insert(deck.id)
        }
    }

    func selectAllDecks() { selectedDeckIDs = Set(Decks.all.map(\.id)) }

    func deselectAllDecks() { selectedDeckIDs = [] }

    /// The deck a round will use. Falls back to the full list rather than
    /// trapping, so a round can never crash on an empty selection.
    func randomDeck() -> Deck {
        selectedDecks.randomElement() ?? Decks.all[0]
    }

    // MARK: Mutations

    func setPlayerCount(_ newValue: Int) {
        let clamped = newValue.clamped(to: Self.playerRange)
        guard clamped != playerCount else { return }
        playerCount = clamped
        syncNames()
        setImposterCount(imposterCount)
    }

    /// Flipping this tightens or loosens the cap, so the current count has to
    /// be pulled back into range.
    func setImpostersKnowEachOther(_ newValue: Bool) {
        guard newValue != impostersKnowEachOther else { return }
        impostersKnowEachOther = newValue
        setImposterCount(imposterCount)
    }

    func setImposterCount(_ newValue: Int) {
        imposterCount = newValue.clamped(to: imposterRange)
    }

    func addPlayer() {
        setPlayerCount(playerCount + 1)
    }

    func removePlayer() {
        setPlayerCount(playerCount - 1)
    }

    func removePlayer(at index: Int) {
        guard playerCount > Self.playerRange.lowerBound,
              playerNames.indices.contains(index) else { return }
        playerNames.remove(at: index)
        playerCount = playerNames.count
        setImposterCount(imposterCount)
    }

    /// Reads a name safely, so a row that renders with a stale index during a
    /// removal animation cannot trap on an out-of-bounds subscript.
    func name(at index: Int) -> String {
        playerNames.indices.contains(index) ? playerNames[index] : ""
    }

    func setName(_ name: String, at index: Int) {
        guard playerNames.indices.contains(index) else { return }
        playerNames[index] = name
    }

    /// Keeps the names array the same length as the player count, without
    /// disturbing names the user has already typed.
    private func syncNames() {
        if playerNames.count < playerCount {
            for index in playerNames.count..<playerCount {
                playerNames.append("Player \(index + 1)")
            }
        } else if playerNames.count > playerCount {
            playerNames.removeLast(playerNames.count - playerCount)
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
