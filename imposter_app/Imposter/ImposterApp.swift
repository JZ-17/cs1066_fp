import SwiftUI

@main
struct ImposterApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

/// Holds the intro, then swaps it for the home screen.
struct RootView: View {

    @State private var showHome = false
    @State private var settings = GameSettings()

    /// Lets a build jump straight to a screen for screenshots:
    ///   xcrun simctl launch <device> <bundle id> -screen setup
    private var screenOverride: String? {
        guard let index = CommandLine.arguments.firstIndex(of: "-screen"),
              CommandLine.arguments.indices.contains(index + 1) else { return nil }
        return CommandLine.arguments[index + 1]
    }

    @State private var flow = GameFlow()

    var body: some View {
        ZStack {
            Theme.inkDeep.ignoresSafeArea()

            switch screenOverride {
            case "setup":
                NavigationStack { GameSetupView(settings: settings, flow: flow) }.tint(Theme.ember)
            case "clues":
                NavigationStack {
                    RoundFlowView(round: {
                        settings.setPlayerCount(6)
                        settings.playerNames = ["Josh","Alan","Logan","Sarah","Mike","Ava"]
                        settings.setImposterCount(2)
                        settings.imposterNeverGoesFirst = true
                        let r = GameRound(settings: settings, deck: Decks.sports)
                        r.phase = .clues
                        return r
                    }(), flow: flow)
                }.tint(Theme.ember)
            case "round":
                NavigationStack {
                    RoundFlowView(round: GameRound(settings: settings, deck: Decks.foods), flow: flow)
                }.tint(Theme.ember)
            case "decks":
                NavigationStack { DeckPickerView(settings: settings) }.tint(Theme.ember)
            case "decks-empty":
                NavigationStack {
                    DeckPickerView(settings: {
                        settings.deselectAllDecks()
                        return settings
                    }())
                }.tint(Theme.ember)
            case "reveal":
                NavigationStack {
                    RoundFlowView(round: {
                        settings.setPlayerCount(5)
                        settings.playerNames = ["Josh","Alan","Logan","Sarah","Mike"]
                        settings.setImposterCount(2)
                        let r = GameRound(settings: settings, deck: Decks.animals)
                        r.phase = .result
                        return r
                    }(), flow: flow)
                }.tint(Theme.ember)
            case "howto":
                NavigationStack { HowToPlayView() }.tint(Theme.ember)
            case "names":
                NavigationStack { PlayerNamesView(settings: settings, flow: flow) }.tint(Theme.ember)
            default:
                if showHome {
                    HomeView()
                        .transition(.opacity)
                } else {
                    LoadingView {
                        withAnimation(.easeInOut(duration: 0.7)) { showHome = true }
                    }
                    .transition(.opacity)
                }
            }
        }
    }
}
