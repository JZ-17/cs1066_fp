import Foundation

/// Custom decks are compiled nowhere, so they come from the server. This keeps
/// the last good copy on disk so the game still works with no signal.
///
/// One JSON file, not a database. Fifty decks of a hundred cards is a few
/// hundred kilobytes, and a whole persistence stack would be more moving parts
/// than the data deserves.
///
/// Every read and write is wrapped. A missing, half written or outdated cache
/// is a normal thing to find, not an error worth telling the player about. In
/// all those cases the game falls back to the three built in decks.
struct DeckCache {

    /// Bumped when the stored shape changes, so an old file is ignored rather
    /// than decoded into something wrong.
    private static let version = 1

    private struct Payload: Codable {
        let version: Int
        let savedAt: Date
        let decks: [StoredDeck]
    }

    private let fileURL: URL?

    init() {
        let folder = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Imposter", isDirectory: true)

        guard let folder else {
            fileURL = nil
            return
        }

        // Application Support is not guaranteed to exist on a fresh install.
        try? FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        fileURL = folder.appendingPathComponent("custom-decks.json")
    }

    /// The decks from the last good fetch, or an empty list.
    func load() -> [StoredDeck] {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(Payload.self, from: data) else { return [] }
        guard payload.version == Self.version else { return [] }
        return payload.decks
    }

    /// When the cache was last written, for a "last updated" line in the UI.
    func savedAt() -> Date? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Payload.self, from: data).savedAt
    }

    func save(_ decks: [StoredDeck]) {
        guard let fileURL else { return }
        let payload = Payload(version: Self.version, savedAt: Date(), decks: decks)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return }

        // .atomic writes to a temporary file and swaps it in. Without it, being
        // killed mid write leaves a truncated file that never decodes again.
        try? data.write(to: fileURL, options: .atomic)
    }

    func clear() {
        guard let fileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
}
