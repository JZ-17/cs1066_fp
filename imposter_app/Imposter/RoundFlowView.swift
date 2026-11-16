import SwiftUI

struct RoundFlowView: View {

    @State var round: GameRound
    @Bindable var flow: GameFlow

    var body: some View {
        ZStack {
            switch round.phase {
            case .reveal:
                RevealPhase(round: round)
                    .transition(.phaseAdvance)
            case .clues:
                CluePhase(round: round)
                    .transition(.phaseAdvance)
            case .result:
                ResultPhase(
                    round: round,
                    playAgain: { flow.playAgain() },
                    menu: { flow.backToMenu() }
                )
                .transition(.phaseAdvance)
            }
        }
        // A ZStack, not a Group: the outgoing phase has to stay on screen and
        // slide out while the incoming one slides in. A Group swaps its child
        // outright and there is nothing left to animate.
        .animation(Theme.smooth, value: round.phase)
        .background { Theme.backdrop }
        .navigationBarBackButtonHidden(round.phase != .reveal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - 1. Pass the device

private struct RevealPhase: View {

    @Bindable var round: GameRound
    @State private var shown = false

    private var index: Int { round.revealPlayer }

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            Text("\(index + 1) of \(round.players.count)")
                .font(Theme.label(14))
                .tracking(3)
                .foregroundStyle(Theme.cream.opacity(0.5))
                .contentTransition(.numericText())

            // Keyed on the player so passing the phone slides the next name in
            // rather than swapping the letters in place.
            Text(round.players[index])
                .font(Theme.display(40))
                .foregroundStyle(Theme.sunset)
                .glow(Theme.orange, radius: 18)
                .id(index)
                .transition(.phaseAdvance)

            ZStack {
                if shown {
                    revealed.transition(.softSwap)
                } else {
                    hidden.transition(.softSwap)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 26)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .animation(Theme.smooth, value: index)
        .animation(Theme.bouncy, value: shown)
    }

    private var hidden: some View {
        VStack(spacing: 18) {
            Text("Everyone else, look away.")
                .font(Theme.label(16))
                .foregroundStyle(Theme.cream.opacity(0.65))

            Button {
                shown = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 30, weight: .bold))
                    Text("Tap to reveal")
                        .font(Theme.label(19))
                }
                .foregroundStyle(Theme.inkDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
                .background(Theme.sunset)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .glow(Theme.orange, radius: 24, strength: 0.9)
            }
            .pressable()
        }
    }

    private var revealed: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                Text(round.secretLabel(for: index))
                    .font(Theme.label(13))
                    .tracking(4)
                    .foregroundStyle(
                        round.isImposter(index) ? Theme.ember : Theme.cream.opacity(0.55)
                    )

                Text(round.secret(for: index))
                    .font(Theme.display(38))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.cream)

                if round.isImposter(index) {
                    Text(round.imposterNote(for: index))
                        .font(Theme.label(15))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ember)

                    let mates = round.teammates(of: index)
                    if !mates.isEmpty {
                        Text("With you: \(mates.joined(separator: ", "))")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.amber.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 38)
            .padding(.horizontal, 20)
            .background(round.isImposter(index) ? Theme.crimson.opacity(0.22) : Theme.ink.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(
                        round.isImposter(index) ? Theme.orange.opacity(0.8) : Theme.cream.opacity(0.15),
                        lineWidth: round.isImposter(index) ? 1.8 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .lift()

            Button {
                shown = false
                round.advanceReveal()
            } label: {
                Label(
                    round.isLastReveal ? "Hide & Start" : "Hide & Pass",
                    systemImage: "arrow.right"
                )
                .font(Theme.label(18))
                .foregroundStyle(Theme.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.cream.opacity(0.3), lineWidth: 1.5)
                )
            }
            .pressable(dims: true)
        }
    }
}

// MARK: - 2. Clues

private struct CluePhase: View {

    @Bindable var round: GameRound

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.ember)
                        Text("\(round.leadPlayer) starts")
                            .font(Theme.display(30))
                            .foregroundStyle(Theme.sunset)
                            .glow(Theme.orange, radius: 14)
                    }
                    Text("Give your clues, talk it out, and vote out loud. Reveal when you have decided.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.cream.opacity(0.65))
                }
                .belowNavigationBar()

                // Guidance, worded for this round's settings.
                VStack(alignment: .leading, spacing: 14) {
                    Text("How This Round Works")
                        .font(Theme.label(15))
                        .foregroundStyle(Theme.cream.opacity(0.8))

                    ForEach(Array(round.briefing.enumerated()), id: \.offset) { position, line in
                        HStack(alignment: .top, spacing: 11) {
                            Text("\(position + 1).")
                                .font(Theme.label(14))
                                .foregroundStyle(Theme.ember)
                                .frame(width: 20, alignment: .leading)
                            Text(line)
                                .font(.system(size: 14.5, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.cream.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.ink.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Theme.cream.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text("Turn Order")
                    .font(Theme.label(15))
                    .foregroundStyle(Theme.cream.opacity(0.8))

                VStack(spacing: 10) {
                    ForEach(Array(round.turnOrder.enumerated()), id: \.offset) { position, player in
                        HStack(spacing: 14) {
                            Text("\(position + 1)")
                                .font(Theme.label(16))
                                .foregroundStyle(Theme.inkDeep)
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(Theme.sunset))
                            Text(round.players[player])
                                .font(Theme.label(18))
                                .foregroundStyle(Theme.cream)
                            Spacer()
                            if position == 0 {
                                Text("STARTS")
                                    .font(Theme.label(11))
                                    .tracking(2)
                                    .foregroundStyle(Theme.amber)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(position == 0 ? Theme.fog.opacity(0.28) : Theme.ink.opacity(0.45))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(
                                    position == 0 ? Theme.orange.opacity(0.6) : Theme.cream.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }

                ArmedRevealButton {
                    round.revealAnswer()
                }
                .padding(.top, 6)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - 3. The reveal

/// No winner is declared here. The group settled that out loud; the app just
/// gives up what it was holding.
private struct ResultPhase: View {

    @Bindable var round: GameRound
    let playAgain: () -> Void
    let menu: () -> Void

    /// Drives the staggered entrance. This screen is the payoff, so the word
    /// lands first and the imposters are dealt out after it rather than the
    /// whole answer appearing at once.
    @State private var appeared = false

    private var imposterNames: [Int] { round.imposters.sorted() }

    /// Fade-and-rise for one element, `step` places it in the running order.
    private func entrance(_ step: Int) -> some ViewModifier {
        Entrance(appeared: appeared, delay: Double(step) * 0.09)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 30)

                Text("THE WORD WAS")
                    .font(Theme.label(12))
                    .tracking(4)
                    .foregroundStyle(Theme.cream.opacity(0.5))
                    .modifier(entrance(0))

                Text(round.card.word)
                    .font(Theme.display(42))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.sunset)
                    .glow(Theme.orange, radius: 22)
                    .scaleEffect(appeared ? 1 : 0.86)
                    .opacity(appeared ? 1 : 0)
                    .animation(Theme.bouncy.delay(0.08), value: appeared)

                Text(round.category)
                    .font(Theme.label(14))
                    .foregroundStyle(Theme.cream.opacity(0.45))
                    .padding(.bottom, 4)
                    .modifier(entrance(2))

                VStack(alignment: .leading, spacing: 10) {
                    Text(imposterNames.count == 1 ? "The Imposter" : "The Imposters")
                        .font(Theme.label(14))
                        .foregroundStyle(Theme.cream.opacity(0.55))
                        .modifier(entrance(3))

                    ForEach(Array(imposterNames.enumerated()), id: \.element) { slot, index in
                        HStack(spacing: 10) {
                            Text("\u{1F575}\u{FE0F}")
                            Text(round.players[index])
                                .font(Theme.label(18))
                                .foregroundStyle(Theme.ember)
                            Spacer(minLength: 8)
                            Text(
                                round.revealedHint(for: index).isEmpty
                                    ? "category only"
                                    : "\u{201C}\(round.revealedHint(for: index))\u{201D}"
                            )
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.cream.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(Theme.crimson.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Theme.orange.opacity(0.55), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .modifier(entrance(4 + slot))
                    }

                    if round.players.count > imposterNames.count {
                        Text("Everyone else had the word.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.cream.opacity(0.4))
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

                PrimaryButton(title: "Play Again", icon: "arrow.clockwise", action: playAgain)
                    .modifier(entrance(5 + imposterNames.count))

                Button(action: menu) {
                    Label("Back to Menu", systemImage: "house.fill")
                        .font(Theme.label(16))
                        .foregroundStyle(Theme.cream.opacity(0.65))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .pressable(scale: 0.95, dims: true)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .onAppear { appeared = true }
    }
}

/// Fade up from slightly below, after a delay. Used to deal the reveal screen
/// out one element at a time.
private struct Entrance: ViewModifier {
    let appeared: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .animation(Theme.smooth.delay(delay), value: appeared)
    }
}

// MARK: - Shared bits

private struct PhaseHeader: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Theme.display(34))
                .foregroundStyle(Theme.sunset)
                .glow(Theme.orange, radius: 16)
            Text(detail)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.cream.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 10)
    }
}

private struct PrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(Theme.label(18))
                .foregroundStyle(Theme.inkDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Theme.sunset)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .glow(Theme.orange, radius: 20, strength: 0.85)
        }
        .pressable()
    }
}

// MARK: - Reveal, behind a second tap

/// Ending the round is destructive and irreversible, so it takes two taps.
/// The first arms the button: it turns red, relabels, and drains a bar across
/// itself. A second tap inside that window reveals; otherwise it disarms
/// itself and goes back to normal, so an accidental tap costs nothing.
///
/// This replaces a `.confirmationDialog`, which threw a system action sheet
/// over the board and broke the feel of the table.
private struct ArmedRevealButton: View {

    let action: () -> Void

    /// How long the armed state lasts before it gives up.
    private let window: Double = 3

    @State private var armed = false
    @State private var drain: CGFloat = 1
    @State private var disarmTask: Task<Void, Never>?

    var body: some View {
        Button {
            if armed {
                fire()
            } else {
                arm()
            }
        } label: {
            Label(
                armed ? "Tap Again to Reveal" : "Reveal the Answer",
                systemImage: armed ? "exclamationmark.triangle.fill" : "eye.fill"
            )
            .font(Theme.label(18))
            .foregroundStyle(armed ? Theme.cream : Theme.inkDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background {
                ZStack(alignment: .leading) {
                    Theme.sunset
                    Theme.crimson.opacity(armed ? 1 : 0)

                    // The time left, draining left to right behind the label.
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Theme.cream.opacity(0.18))
                            .frame(width: geo.size.width * drain)
                    }
                    .opacity(armed ? 1 : 0)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.cream.opacity(armed ? 0.5 : 0), lineWidth: 1.5)
            )
            .glow(armed ? Theme.crimson : Theme.orange, radius: 20, strength: 0.85)
        }
        .pressable()
        .sensoryFeedback(.warning, trigger: armed) { _, now in now }
        .accessibilityLabel(armed ? "Tap again to reveal the answer" : "Reveal the answer")
        .accessibilityHint("Takes two taps. Ends the round for everyone.")
        .onDisappear { disarmTask?.cancel() }
    }

    private func arm() {
        disarmTask?.cancel()
        drain = 1
        withAnimation(Theme.quick) { armed = true }
        withAnimation(.linear(duration: window)) { drain = 0 }

        disarmTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(window))
            guard !Task.isCancelled else { return }
            withAnimation(Theme.smooth) { armed = false }
            drain = 1
        }
    }

    private func fire() {
        reset()
        action()
    }

    /// Clears the armed state without animating, so the button is already back
    /// to normal if the view comes around again.
    private func reset() {
        disarmTask?.cancel()
        disarmTask = nil
        armed = false
        drain = 1
    }
}
