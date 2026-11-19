import SwiftUI

/// Browsing the decks themselves.
///
/// Different job from the deck picker. The picker chooses which decks a round
/// may draw from. This one is where decks are made, renamed, edited and thrown
/// away.
struct DeckLibraryView: View {

    @Bindable var library: DeckLibrary

    @State private var renaming: StoredDeck?
    @State private var newName = ""
    @State private var deckToDelete: StoredDeck?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Decks")
                    .font(Theme.display(34))
                    .foregroundStyle(Theme.visor)
                    .glow(Theme.beacon, radius: 16)
                    .belowNavigationBar()

                generateButton

                if !library.stored.isEmpty {
                    SectionLabel(icon: "square.stack.3d.up.fill", title: "Yours")

                    ForEach(library.stored) { deck in
                        NavigationLink(value: Route.customDeck(deck.id)) {
                            DeckRowFace(
                                symbol: deck.symbol,
                                name: deck.name,
                                detail: "\(deck.cards.count) words",
                                locked: false
                            )
                        }
                        .pressable(scale: 0.98)
                        .contextMenu {
                            Button {
                                newName = deck.name
                                renaming = deck
                            } label: { Label("Rename", systemImage: "pencil") }

                            Button(role: .destructive) {
                                deckToDelete = deck
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }

                SectionLabel(icon: "lock.fill", title: "Built In")

                ForEach(Decks.all) { deck in
                    NavigationLink(value: Route.builtInDeck(deck.id)) {
                        DeckRowFace(
                            symbol: deck.symbol,
                            name: deck.name,
                            detail: "\(deck.cards.count) words",
                            locked: true
                        )
                    }
                    .pressable(scale: 0.98)
                }

                footer
                    .padding(.top, 6)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.backdrop }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .spaceBackButton()
        // Loads its own data if whoever pushed this screen has not. Without
        // this the view depends on a caller it cannot see.
        .task { if library.status == .idle { await library.start() } }
        .refreshable { await library.refresh() }
        .alert("Rename deck", isPresented: Binding(
            get: { renaming != nil },
            set: { if !$0 { renaming = nil } }
        )) {
            TextField("Deck name", text: $newName)
            Button("Cancel", role: .cancel) { renaming = nil }
            Button("Save") {
                guard let deck = renaming else { return }
                renaming = nil
                Task { await run { try await library.rename(deckID: deck.id, to: newName) } }
            }
        }
        .confirmationDialog(
            "Delete \(deckToDelete?.name ?? "this deck")?",
            isPresented: Binding(
                get: { deckToDelete != nil },
                set: { if !$0 { deckToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let deck = deckToDelete else { return }
                deckToDelete = nil
                Task { await run { try await library.deleteDeck(deck.id) } }
            }
            Button("Keep", role: .cancel) { deckToDelete = nil }
        } message: {
            Text("Its words go too. This cannot be undone.")
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

    /// Runs a write and turns any failure into a readable alert.
    private func run(_ work: () async throws -> Void) async {
        do { try await work() } catch { errorMessage = error.localizedDescription }
    }

    private var generateButton: some View {
        Button {
            // The generator is not built yet.
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18, weight: .bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Generate a Deck")
                        .font(Theme.label(18))
                    Text(library.isAtLimit
                         ? "You are at 50. Delete one first."
                         : "Pick a topic and get 100 words")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .opacity(0.75)
                }
                Spacer(minLength: 8)
            }
            .foregroundStyle(Theme.deepSpace)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Theme.visor)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .glow(Theme.beacon, radius: 18, strength: 0.8)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .pressable()
        .disabled(true)
        .opacity(0.55)
        .overlay(alignment: .topTrailing) {
            Text("SOON")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(Theme.deepSpace)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Theme.warning)
                .clipShape(Capsule())
                .offset(x: -10, y: 10)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 12, weight: .bold))
            Text(statusText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .foregroundStyle(Theme.starlight.opacity(0.5))
    }

    private var statusIcon: String {
        switch library.status {
        case .live:     "checkmark.icloud.fill"
        case .offline:  "icloud.slash.fill"
        case .loading:  "arrow.triangle.2.circlepath"
        case .failed:   "exclamationmark.icloud.fill"
        case .idle:     "icloud.slash"
        }
    }

    private var statusText: String {
        switch library.status {
        case .live:
            "\(library.stored.count) of \(DeckLibrary.deckLimit) used"
        case .offline:
            "Offline. Showing your last saved copy."
        case .loading:
            "Checking for changes."
        case .failed(let why):
            why
        case .idle:
            SupabaseConfig.isConfigured
                ? "Not loaded yet."
                : "Custom decks are switched off."
        }
    }
}

// MARK: - One row

private struct DeckRowFace: View {
    let symbol: String
    let name: String
    let detail: String
    let locked: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(symbol)
                .font(.system(size: 24))
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Theme.hull.opacity(0.85))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(Theme.label(18))
                    .foregroundStyle(Theme.starlight)
                Text(detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.starlight.opacity(0.55))
            }

            Spacer(minLength: 10)

            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.starlight.opacity(0.3))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.starlight.opacity(0.35))
        }
        .padding(14)
        .background(Theme.hull.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.starlight.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// SectionLabel lives in GameSetupView.swift and is reused here.
