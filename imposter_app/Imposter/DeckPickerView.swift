import SwiftUI

/// Chooses which decks a round may draw its word from. Reached from the
/// Decks row on the game setup screen.
struct DeckPickerView: View {

    @Bindable var settings: GameSettings

    private var allSelected: Bool { settings.selectedDecks.count == Decks.all.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                Text("Decks")
                    .font(Theme.display(38))
                    .foregroundStyle(Theme.sunset)
                    .glow(Theme.orange, radius: 16)
                    .belowNavigationBar()

                Text("Each round draws its word from one of the decks below, picked at random. Turn off the ones you do not want in play.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.cream.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 2)

                HStack(spacing: 12) {
                    BulkButton(
                        title: "Select All",
                        icon: "checkmark.circle.fill",
                        enabled: !allSelected
                    ) {
                        withAnimation(Theme.bouncy) { settings.selectAllDecks() }
                    }
                    BulkButton(
                        title: "Deselect All",
                        icon: "xmark.circle",
                        enabled: settings.canStart
                    ) {
                        withAnimation(Theme.bouncy) { settings.deselectAllDecks() }
                    }
                }
                .padding(.bottom, 4)

                ForEach(Decks.all) { deck in
                    DeckRow(deck: deck, selected: settings.isSelected(deck)) {
                        withAnimation(Theme.bouncy) { settings.toggle(deck) }
                    }
                }

                footer
                    .padding(.top, 6)
                    .padding(.bottom, 44)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.backdrop }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    /// Doubles as the empty-state warning, since deselecting everything is
    /// allowed but cannot start a game.
    @ViewBuilder
    private var footer: some View {
        if settings.canStart {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.amber)
                Text("\(settings.selectedCardCount) words in play")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.cream.opacity(0.7))
            }
        } else {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.ember)
                Text("Pick at least one deck. A round needs somewhere to draw its word from.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ember)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Theme.crimson.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.orange.opacity(0.5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - One deck

private struct DeckRow: View {

    let deck: Deck
    let selected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 14) {
                Text(deck.symbol)
                    .font(.system(size: 24))
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(selected ? Theme.crimson.opacity(0.35) : Theme.ink.opacity(0.85))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(deck.name)
                        .font(Theme.label(18))
                        .foregroundStyle(Theme.cream)
                    Text("\(deck.cards.count) words")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.cream.opacity(0.55))
                }

                Spacer(minLength: 10)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(selected ? Theme.ember : Theme.cream.opacity(0.3))
                    .contentTransition(.symbolEffect(.replace))
                    .scaleEffect(selected ? 1.08 : 1)
            }
            .padding(14)
            .background(selected ? Theme.ink.opacity(0.75) : Theme.ink.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        selected ? Theme.orange.opacity(0.65) : Theme.cream.opacity(0.1),
                        lineWidth: selected ? 1.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .lift(radius: selected ? 16 : 8, y: selected ? 8 : 4)
            .animation(Theme.bouncy, value: selected)
        }
        .pressable(scale: 0.98)
    }
}

// MARK: - Select all / deselect all

private struct BulkButton: View {

    let title: String
    let icon: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(Theme.label(15))
            }
            .foregroundStyle(enabled ? Theme.cream : Theme.cream.opacity(0.3))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Theme.ink.opacity(enabled ? 0.7 : 0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(
                        enabled ? Theme.cream.opacity(0.18) : Theme.cream.opacity(0.07),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .pressable(scale: 0.95, dims: true)
        .disabled(!enabled)
    }
}

#Preview {
    NavigationStack { DeckPickerView(settings: GameSettings()) }
        .preferredColorScheme(.dark)
}
