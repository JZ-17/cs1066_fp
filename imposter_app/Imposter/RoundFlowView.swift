import SwiftUI

struct RoundFlowView: View {

    @State var round: GameRound
    @Bindable var flow: GameFlow

    var body: some View {
        Group {
            switch round.phase {
            case .reveal: RevealPhase(round: round)
            case .clues:  CluePhase(round: round)
            case .result: ResultPhase(
                round: round,
                playAgain: { flow.playAgain() },
                menu: { flow.backToMenu() }
            )
            }
        }
        .animation(.snappy(duration: 0.3), value: round.phase)
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

            Text(round.players[index])
                .font(Theme.display(40))
                .foregroundStyle(Theme.sunset)
                .glow(Theme.orange, radius: 18)

            if shown {
                revealed
            } else {
                hidden
            }

            Spacer()
        }
        .padding(.horizontal, 26)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }

    private var hidden: some View {
        VStack(spacing: 18) {
            Text("Everyone else, look away.")
                .font(Theme.label(16))
                .foregroundStyle(Theme.cream.opacity(0.65))

            Button {
                withAnimation(.snappy) { shown = true }
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
            .buttonStyle(.plain)
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
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 2. Clues

private struct CluePhase: View {

    @Bindable var round: GameRound
    @State private var confirming = false

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

                PrimaryButton(title: "Reveal the Answer", icon: "eye.fill") {
                    confirming = true
                }
                .padding(.top, 6)
                .padding(.bottom, 40)
                .confirmationDialog(
                    "Reveal the word and the imposters?",
                    isPresented: $confirming,
                    titleVisibility: .visible
                ) {
                    Button("Reveal", role: .destructive) { round.revealAnswer() }
                    Button("Keep Playing", role: .cancel) { }
                } message: {
                    Text("This ends the round for everyone.")
                }
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

    private var imposterNames: [Int] { round.imposters.sorted() }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 30)

                Text("THE WORD WAS")
                    .font(Theme.label(12))
                    .tracking(4)
                    .foregroundStyle(Theme.cream.opacity(0.5))

                Text(round.card.word)
                    .font(Theme.display(42))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.sunset)
                    .glow(Theme.orange, radius: 22)

                Text(round.category)
                    .font(Theme.label(14))
                    .foregroundStyle(Theme.cream.opacity(0.45))
                    .padding(.bottom, 4)

                VStack(alignment: .leading, spacing: 10) {
                    Text(imposterNames.count == 1 ? "The Imposter" : "The Imposters")
                        .font(Theme.label(14))
                        .foregroundStyle(Theme.cream.opacity(0.55))

                    ForEach(imposterNames, id: \.self) { index in
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

                Button(action: menu) {
                    Label("Back to Menu", systemImage: "house.fill")
                        .font(Theme.label(16))
                        .foregroundStyle(Theme.cream.opacity(0.65))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
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
        .buttonStyle(.plain)
    }
}
