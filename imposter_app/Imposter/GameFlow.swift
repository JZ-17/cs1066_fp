import Foundation
import Observation

/// Screens the home stack can push.
enum Route: Hashable {
    case setup
    case decks
    case names
    case round
}

/// Owns the navigation stack and the round in progress.
///
/// The path lives here rather than in each screen because "Play Again" has to
/// pop two levels at once, back to Game Settings — something `dismiss()`
/// cannot express. Driving `NavigationStack(path:)` directly makes that a
/// one-line assignment.
@Observable
final class GameFlow {

    var path: [Route] = []

    /// The round being played. Built when the group starts, cleared when they
    /// come back, so a finished round never leaks into the next one.
    var round: GameRound?

    func newGame() {
        round = nil
        path = [.setup]
    }

    func startRound(settings: GameSettings) {
        round = GameRound(settings: settings, deck: settings.randomDeck())
        path.append(.round)
    }

    /// Back to Game Settings, keeping the players and settings as they were.
    func playAgain() {
        round = nil
        path = [.setup]
    }

    func backToMenu() {
        round = nil
        path = []
    }
}
