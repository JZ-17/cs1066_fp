import Foundation
import Observation

enum RoundPhase: Hashable {
    case reveal        // passing the device around
    case clues         // everyone takes turns out loud
    case result        // the word and the imposters, revealed
}

/// One playthrough. Built from `GameSettings` plus a deck, then driven
/// forward by the round screens.
///
/// As with `GameSettings`, no `didSet` observers: the `@Observable` macro
/// makes stored properties computed, so assigning inside an observer recurses.
@Observable
final class GameRound {

    let players: [String]
    let card: Card

    /// The deck's name — "Animals", "Foods". This is all a blind imposter is
    /// given, and it is the baseline difficulty for the role.
    let category: String

    let imposters: Set<Int>
    let impostersKnowEachOther: Bool

    /// In random mode the group is not told how many imposters there are.
    let imposterCountIsSecret: Bool
    let imposterNeverGoesFirst: Bool

    /// Whether imposters were handed a hint word on top of the category.
    let imposterGetsHint: Bool

    /// The hint each imposter was handed, when `imposterGetsHint` is on;
    /// empty otherwise. Different imposters draw different hints where the
    /// card has enough of them, so their clues do not converge into an
    /// obvious matching pair.
    let hints: [Int: String]

    /// Seating order for the clue phase.
    let turnOrder: [Int]

    var phase: RoundPhase = .reveal
    var revealIndex: Int = 0

    init(settings: GameSettings, deck: Deck) {
        let names = Array(settings.playerNames.prefix(settings.playerCount))
        players = names
        card = deck.cards.randomElement() ?? Card.fallback
        category = deck.name
        impostersKnowEachOther = settings.impostersKnowEachOther
        imposterCountIsSecret = settings.imposterMode == .random
        imposterNeverGoesFirst = settings.imposterNeverGoesFirst
        imposterGetsHint = settings.imposterGetsHint

        let count: Int
        switch settings.imposterMode {
        case .fixed:  count = settings.imposterCount
        case .random: count = Int.random(in: settings.imposterRange)
        }
        let chosen = Set(names.indices.shuffled().prefix(count))
        imposters = chosen

        var assigned: [Int: String] = [:]
        if settings.imposterGetsHint {
            var pool = card.hints.shuffled()
            for index in chosen.sorted() {
                if pool.isEmpty { pool = card.hints.shuffled() }
                assigned[index] = pool.removeFirst()
            }
        }
        hints = assigned

        var order = names.indices.shuffled()
        // "Imposter never goes first" only matters if someone else can lead.
        if settings.imposterNeverGoesFirst,
           let leader = order.first, chosen.contains(leader),
           let swap = order.firstIndex(where: { !chosen.contains($0) }) {
            order.swapAt(0, swap)
        }
        turnOrder = order
    }

    // MARK: Reveal

    var revealPlayer: Int { revealIndex }
    var isLastReveal: Bool { revealIndex >= players.count - 1 }

    func isImposter(_ index: Int) -> Bool { imposters.contains(index) }

    /// What this player sees when they tap their name. Innocents get the word.
    /// An imposter gets their hint if hints are on, and otherwise the category
    /// alone — which is the whole difficulty of the default mode.
    func secret(for index: Int) -> String {
        guard isImposter(index) else { return card.word }
        return hints[index] ?? category
    }

    /// Caption above the reveal, so the imposter knows what they are holding.
    func secretLabel(for index: Int) -> String {
        guard isImposter(index) else { return "THE WORD" }
        return hints[index] == nil ? "YOUR CATEGORY" : "YOUR HINT"
    }

    /// The line under an imposter's reveal.
    func imposterNote(for index: Int) -> String {
        hints[index] == nil
            ? "You are the imposter. The category is all you get — listen hard."
            : "You are the imposter. Blend in."
    }

    /// Teammates to name, when imposters are told about each other.
    func teammates(of index: Int) -> [String] {
        guard impostersKnowEachOther, isImposter(index) else { return [] }
        return imposters.filter { $0 != index }.sorted().map { players[$0] }
    }

    func advanceReveal() {
        if isLastReveal {
            phase = .clues
        } else {
            revealIndex += 1
        }
    }

    // MARK: Briefing

    var leadPlayer: String { players[turnOrder.first ?? 0] }

    /// Clue-phase guidance, worded for the settings this round is using.
    var briefing: [String] {
        var lines = [
            "Start with \(leadPlayer) and follow the order below.",
            "Say one word connected to the secret. Not a sentence, not a definition.",
            "Go around at least twice before you settle on anyone. A single pass almost never gives the group enough to work with.",
        ]

        if imposterCountIsSecret {
            lines.append("The number of imposters is random this round. It could be one. It could be more.")
        } else if imposters.count == 1 {
            lines.append("There is exactly one imposter at the table.")
        } else {
            lines.append("There are \(imposters.count) imposters at the table.")
        }

        lines.append(
            imposterGetsHint
                ? "The deck is \(category), and imposters were given a hint word. Expect their clues to land close to the mark."
                : "The deck is \(category), and that is all the imposters know. Early clues are a guess for them, so watch who plays it safe."
        )

        if imposters.count > 1 || imposterCountIsSecret {
            lines.append(
                impostersKnowEachOther
                    ? "Any imposters know who each other are, so expect them to cover for one another."
                    : "Imposters do not know who each other are, so they may well accuse a teammate."
            )
        }

        if imposterNeverGoesFirst {
            lines.append("\(leadPlayer) is innocent for certain — an imposter never leads.")
        }

        return lines
    }

    // MARK: Reveal the answer

    /// Ends the round. The group votes and argues out loud; the app only
    /// holds the secret, so all it has to do is give it up.
    func revealAnswer() {
        phase = .result
    }

    /// What each imposter was holding, for the reveal screen. Empty string
    /// when they were playing on the category alone.
    func revealedHint(for index: Int) -> String {
        hints[index] ?? ""
    }
}

private extension Card {
    static let fallback = Card(word: "Pizza", hints: ["delivery", "slice", "friday", "box", "shared"])
}
