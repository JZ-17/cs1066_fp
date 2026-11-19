import Foundation
import Observation
import SwiftUI

/// Screens the home stack can push.
enum Route: Hashable {
    case setup
    /// Choosing which decks a round may draw from.
    case decks
    case names
    case round

    /// Browsing and editing the decks themselves, which is a different job
    /// from picking which ones are in play.
    case library
    case customDeck(UUID)
    case builtInDeck(String)
}

/// Owns the navigation stack and the round in progress.
///
/// The path lives here rather than in each screen. "Play Again" has to pop
/// two levels at once, back to Game Settings. `dismiss()` cannot express
/// that. Driving `NavigationStack(path:)` directly makes it one line.
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

    // MARK: Leaving a round

    /// Where the group is headed when they leave a finished round.
    enum Exit {
        case settings   // Play Again
        case menu       // Back to Menu

        var title: String {
            switch self {
            case .settings: "NEXT ROUND"
            case .menu:     "RETURNING TO BASE"
            }
        }
    }

    /// True while the screen is covered mid-rewind.
    private(set) var leaving: Exit?

    /// Rewinds the stack behind a cover.
    ///
    /// Both exits pop more than one level at once. Play Again drops two and
    /// Back to Menu drops three. `NavigationStack` renders that as one hard
    /// cut, with the screens in between flashing past. Covering the swap
    /// turns it into a deliberate beat instead.
    ///
    /// The state change itself still goes through `playAgain()` and
    /// `backToMenu()` unchanged, so what the tests verify is what runs.
    func exitRound(_ exit: Exit) {
        guard leaving == nil else { return }   // ignore a double tap
        withAnimation(.easeIn(duration: 0.26)) { leaving = exit }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }

            // Behind the cover, and with animation off, so the pop itself is
            // never rendered.
            var silent = Transaction()
            silent.disablesAnimations = true
            withTransaction(silent) {
                switch exit {
                case .settings: self.playAgain()
                case .menu:     self.backToMenu()
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeOut(duration: 0.42)) { self.leaving = nil }
            }
        }
    }
}
