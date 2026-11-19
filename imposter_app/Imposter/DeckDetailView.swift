import SwiftUI

/// The words inside one custom deck, each editable.
struct DeckDetailView: View {

    @Bindable var library: DeckLibrary
    let deckID: UUID

    @State private var editing: StoredCard?
    @State private var cardToDelete: StoredCard?
    @State private var errorMessage: String?

    private var deck: StoredDeck? {
        library.stored.first { $0.id == deckID }
    }

    var body: some View {
        Group {
            if let deck {
                content(deck)
            } else {
                // The deck was deleted, or a refresh dropped it.
                ContentUnavailableView(
                    "Deck is gone",
                    systemImage: "rectangle.stack.badge.minus",
                    description: Text("It was deleted, here or on another device.")
                )
            }
        }
        .background { Theme.backdrop }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .spaceBackButton()
        .sheet(item: $editing) { card in
            CardEditorView(card: card) { edited in
                Task { await run { try await library.updateCard(edited, in: deckID) } }
            }
        }
        .confirmationDialog(
            "Delete \u{201C}\(cardToDelete?.word ?? "")\u{201D}?",
            isPresented: Binding(
                get: { cardToDelete != nil },
                set: { if !$0 { cardToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let card = cardToDelete else { return }
                cardToDelete = nil
                Task { await run { try await library.deleteCard(card.id, from: deckID) } }
            }
            Button("Keep", role: .cancel) { cardToDelete = nil }
        }
        .alert("Could not do that", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func content(_ deck: StoredDeck) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text(deck.symbol).font(.system(size: 30))
                    Text(deck.name)
                        .font(Theme.display(30))
                        .foregroundStyle(Theme.visor)
                        .glow(Theme.beacon, radius: 14)
                }
                .belowNavigationBar()

                Text("\(deck.cards.count) words. Tap one to edit its hints.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.starlight.opacity(0.6))
                    .padding(.bottom, 4)

                ForEach(deck.cards.sorted { $0.position < $1.position }) { card in
                    Button {
                        editing = card
                    } label: {
                        CardRowFace(card: card)
                    }
                    .pressable(scale: 0.98)
                    .contextMenu {
                        Button(role: .destructive) {
                            cardToDelete = card
                        } label: { Label("Delete word", systemImage: "trash") }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 40)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    private func run(_ work: () async throws -> Void) async {
        do { try await work() } catch { errorMessage = error.localizedDescription }
    }
}

// MARK: - A built in deck, which can be read but not changed

struct BuiltInDeckView: View {

    let deck: Deck

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text(deck.symbol).font(.system(size: 30))
                    Text(deck.name)
                        .font(Theme.display(30))
                        .foregroundStyle(Theme.visor)
                        .glow(Theme.beacon, radius: 14)
                }
                .belowNavigationBar()

                HStack(spacing: 7) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Built in. \(deck.cards.count) words, and they cannot be changed.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Theme.starlight.opacity(0.6))
                .padding(.bottom, 4)

                ForEach(Array(deck.cards.enumerated()), id: \.offset) { _, card in
                    CardRowFace(
                        card: StoredCard(word: card.word, hints: card.hints, position: 0)
                    )
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 40)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.backdrop }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .spaceBackButton()
    }
}

// MARK: - One word and its hints

private struct CardRowFace: View {
    let card: StoredCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.word)
                .font(Theme.label(17))
                .foregroundStyle(Theme.starlight)

            // The hints wrap rather than scroll, so a long one is still read.
            HStack(spacing: 6) {
                ForEach(Array(card.hints.enumerated()), id: \.offset) { _, hint in
                    Text(hint)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.signal.opacity(0.85))
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Theme.beacon.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.hull.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.starlight.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
