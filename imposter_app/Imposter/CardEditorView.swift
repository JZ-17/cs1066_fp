import SwiftUI

/// Edit one word and its five hints.
///
/// The same rule the database enforces is checked here first, so a player gets
/// a sentence instead of a 400 from Postgres. The database is still the thing
/// that actually guarantees it.
struct CardEditorView: View {

    let card: StoredCard
    let onSave: (StoredCard) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var word: String
    @State private var hints: [String]
    @FocusState private var focused: Field?

    private enum Field: Hashable {
        case word
        case hint(Int)
    }

    init(card: StoredCard, onSave: @escaping (StoredCard) -> Void) {
        self.card = card
        self.onSave = onSave
        _word = State(initialValue: card.word)
        // Pad or trim to exactly five, so an odd row from the server still
        // opens in a usable editor rather than crashing on an index.
        var padded = card.hints
        while padded.count < 5 { padded.append("") }
        _hints = State(initialValue: Array(padded.prefix(5)))
    }

    private var problem: String? {
        if word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "The word cannot be empty."
        }
        return DeckLibrary.problemWithHints(hints)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    field(
                        label: "THE WORD",
                        text: $word,
                        prompt: "Pizza",
                        field: .word
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("FIVE HINTS")
                            .font(Theme.label(12))
                            .tracking(3)
                            .foregroundStyle(Theme.starlight.opacity(0.5))

                        Text("One or two words each. An imposter gets one of these at random, so none of them should give the word away on its own.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.starlight.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)

                        ForEach(0..<5, id: \.self) { index in
                            hintField(index)
                        }
                    }

                    if let problem {
                        Label(problem, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.warning)
                            .padding(.top, 2)
                    }
                }
                .padding(22)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background { Theme.backdrop }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.starlight.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(Theme.label(17))
                        .foregroundStyle(problem == nil ? Theme.signal : Theme.starlight.opacity(0.3))
                        .disabled(problem != nil)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = nil }
                        .font(Theme.label(17))
                        .foregroundStyle(Theme.signal)
                }
            }
        }
    }

    private func save() {
        var edited = card
        edited.word = word.trimmingCharacters(in: .whitespacesAndNewlines)
        edited.hints = hints.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        onSave(edited)
        dismiss()
    }

    private func field(
        label: String,
        text: Binding<String>,
        prompt: String,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Theme.label(12))
                .tracking(3)
                .foregroundStyle(Theme.starlight.opacity(0.5))
            box(text: text, prompt: prompt, field: field)
        }
    }

    private func hintField(_ index: Int) -> some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(Theme.label(13))
                .foregroundStyle(Theme.deepSpace)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Theme.visor))

            box(
                text: $hints[index],
                prompt: "hint \(index + 1)",
                field: .hint(index)
            )
        }
    }

    private func box(text: Binding<String>, prompt: String, field: Field) -> some View {
        let isEditing = focused == field
        return TextField(
            "",
            text: text,
            prompt: Text(prompt).foregroundColor(Theme.starlight.opacity(0.3))
        )
        .font(Theme.label(16))
        .foregroundStyle(Theme.starlight)
        .tint(Theme.signal)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .focused($focused, equals: field)
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Theme.deepSpace.opacity(isEditing ? 0.8 : 0.55))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isEditing ? Theme.beacon.opacity(0.9) : Theme.starlight.opacity(0.18),
                    lineWidth: isEditing ? 2 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .animation(Theme.quick, value: isEditing)
    }
}
