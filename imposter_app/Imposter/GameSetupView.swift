import SwiftUI

struct GameSetupView: View {

    @Bindable var settings: GameSettings
    @Bindable var flow: GameFlow
    @FocusState private var editing: SetupField?

    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 26) {

                    Text("Game Settings")
                        .font(Theme.display(38))
                        .foregroundStyle(Theme.visor)
                        .glow(Theme.beacon, radius: 16)
                        .belowNavigationBar()

                    SectionLabel(icon: "person.3.fill", title: "Players")
                    Panel {
                        StepperRow(
                            value: Binding(
                                get: { settings.playerCount },
                                set: { settings.setPlayerCount($0) }
                            ),
                            range: GameSettings.playerRange,
                            focus: $editing,
                            field: .players,
                            footnote: "Range: 3 – 100 · tap the number to type"
                        )
                    }

                    SectionLabel(icon: "rectangle.stack.fill", title: "Decks")

                    NavigationLink(value: Route.decks) {
                        Panel {
                            HStack(spacing: 13) {
                                Image(systemName: "rectangle.stack.fill")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Theme.starlight.opacity(0.65))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Word Decks")
                                        .font(Theme.label(16))
                                        .foregroundStyle(Theme.starlight)
                                    Text(settings.deckSummary)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(
                                            settings.canStart ? Theme.starlight.opacity(0.5) : Theme.signal
                                        )
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.starlight.opacity(0.35))
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                        }
                    }
                    .pressable(scale: 0.98, dims: true)

                    SectionLabel(icon: "gamecontroller.fill", title: "Select Imposters")

                    OptionPanel(
                        icon: "number",
                        title: "Fixed",
                        subtitle: "Choose exact imposter count",
                        selected: settings.imposterMode == .fixed
                    ) {
                        settings.imposterMode = .fixed
                    } expanded: {
                        StepperRow(
                            value: Binding(
                                get: { settings.imposterCount },
                                set: { settings.setImposterCount($0) }
                            ),
                            range: settings.imposterRange,
                            focus: $editing,
                            field: .imposters,
                            badge: settings.imposterCount == settings.recommendedImposters
                                ? "Recommended" : nil,
                            footnote: "Range: \(settings.imposterRange.lowerBound) – \(settings.imposterRange.upperBound) · tap the number to type"
                        )
                    }

                    OptionPanel(
                        icon: "shuffle",
                        title: "Random",
                        subtitle: "Randomize imposter count each game",
                        selected: settings.imposterMode == .random
                    ) {
                        settings.imposterMode = .random
                    }

                    Panel {
                        Toggle(isOn: $settings.imposterNeverGoesFirst) {
                            HStack(spacing: 12) {
                                Image(systemName: "nosign")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Theme.starlight.opacity(0.65))
                                Text("Imposter Never Goes First")
                                    .font(Theme.label(16))
                                    .foregroundStyle(Theme.starlight)
                            }
                        }
                        .tint(Theme.beacon)
                        .padding(.vertical, 4)
                    }

                    Panel {
                        Toggle(isOn: $settings.imposterGetsHint) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Theme.starlight.opacity(0.65))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Give Imposters a Hint")
                                        .font(Theme.label(16))
                                        .foregroundStyle(Theme.starlight)
                                    Text("Off: the imposter only sees the category, like “Animals”. On: they also get one random hint word. That makes bluffing much easier.")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(Theme.starlight.opacity(0.5))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .tint(Theme.beacon)
                        .padding(.vertical, 4)
                    }

                    if settings.imposterMode == .random || settings.imposterCount > 1 {
                        Panel {
                            Toggle(isOn: Binding(
                                get: { settings.impostersKnowEachOther },
                                set: { settings.setImpostersKnowEachOther($0) }
                            )) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "person.2.badge.key.fill")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(Theme.starlight.opacity(0.65))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Imposters Know Each Other")
                                            .font(Theme.label(16))
                                            .foregroundStyle(Theme.starlight)
                                        Text("On: they can cover for each other, so fewer are allowed. Off: they play blind and might accuse a teammate.")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(Theme.starlight.opacity(0.5))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .tint(Theme.beacon)
                            .padding(.vertical, 4)
                        }
                    }

                    NavigationLink(value: Route.names) {
                        HStack(spacing: 10) {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                        .font(Theme.label(19))
                        .foregroundStyle(Theme.deepSpace)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.visor)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .glow(Theme.beacon, radius: 22, strength: 0.9)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 22)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
        }
        .background { Theme.backdrop }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { editing = nil }
                    .font(Theme.label(17))
                    .foregroundStyle(Theme.signal)
            }
        }
    }
}

// MARK: - Pieces

struct SectionLabel: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.signal)
            Text(title)
                .font(Theme.label(17))
                .foregroundStyle(Theme.starlight.opacity(0.85))
        }
    }
}

/// Smoked-glass container used for every grouped control.
struct Panel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Theme.hull.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.starlight.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .lift(radius: 14, y: 7)
    }
}

/// Big minus / value / plus control. The value tile carries the gradient so
/// the current number is the brightest thing in the panel.
/// Which number field on this screen has the keyboard.
enum SetupField: Hashable {
    case players
    case imposters
}

/// Minus / number / plus. The number is a real text field, because stepping
/// from 4 to 60 one tap at a time is not a reasonable thing to ask of anyone.
///
/// Typing is *not* clamped keystroke by keystroke: typing "1" on the way to
/// "10" would otherwise snap to the 3 floor and eat the next digit. The value
/// is clamped once, on commit.
struct StepperRow: View {

    @Binding var value: Int
    let range: ClosedRange<Int>
    var focus: FocusState<SetupField?>.Binding
    let field: SetupField
    var badge: String? = nil
    var footnote: String? = nil

    @State private var text: String = ""

    private var isEditing: Bool { focus.wrappedValue == field }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 22) {
                stepButton("minus", enabled: value > range.lowerBound) { step(-1) }

                numberField

                stepButton("plus", enabled: value < range.upperBound) { step(1) }
            }

            if let badge {
                Text(badge)
                    .font(Theme.label(13))
                    .foregroundStyle(Theme.warning)
            }
            if let footnote {
                Text(footnote)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.starlight.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear { text = "\(value)" }
        .onChange(of: value) { _, new in
            if !isEditing { text = "\(new)" }
        }
        .onChange(of: focus.wrappedValue) { old, _ in
            if old == field { commit() }
        }
    }

    private var numberField: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(Theme.display(34))
            .foregroundStyle(Theme.deepSpace)
            .tint(Theme.deepSpace)
            .focused(focus, equals: field)
            .frame(width: 104, height: 84)
            .background(Theme.visor)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        isEditing ? Theme.starlight.opacity(0.95) : Theme.deepSpace.opacity(0.4),
                        lineWidth: isEditing ? 3 : 2
                    )
            )
            .overlay(alignment: .bottomTrailing) {
                // Small affordance so the chip reads as something you can type in.
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.deepSpace.opacity(isEditing ? 0 : 0.5))
                    .padding(7)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .glow(Theme.beacon, radius: 18, strength: 0.8)
            .animation(Theme.quick, value: isEditing)
            .onChange(of: text) { _, new in
                // numberPad still admits paste and dictation, so filter here.
                let digits = String(new.filter(\.isNumber).prefix(3))
                if digits != new { text = digits }
            }
    }

    /// Steps commit whatever is half-typed first, so the two inputs agree.
    private func step(_ delta: Int) {
        if isEditing { focus.wrappedValue = nil }
        let next = (value + delta).clamped(to: range)
        value = next
        text = "\(next)"
    }

    private func commit() {
        let parsed = Int(text) ?? value
        let clamped = parsed.clamped(to: range)
        value = clamped
        text = "\(clamped)"
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(enabled ? Theme.starlight : Theme.starlight.opacity(0.22))
                .frame(width: 66, height: 66)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.starlight.opacity(enabled ? 0.25 : 0.1), lineWidth: 1.5)
                )
                // Without this only the glyph and the 1.5pt outline are
                // tappable. The rest of the 66pt square is empty space, and
                // SwiftUI does not hit-test empty space.
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .pressable(scale: 0.9, dims: true)
        .disabled(!enabled)
    }
}

/// A selectable mode, with optional controls that appear once it is chosen.
struct OptionPanel<Expanded: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let selected: Bool
    let select: () -> Void
    @ViewBuilder var expanded: Expanded

    init(
        icon: String,
        title: String,
        subtitle: String,
        selected: Bool,
        select: @escaping () -> Void,
        @ViewBuilder expanded: () -> Expanded = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.selected = selected
        self.select = select
        self.expanded = expanded()
    }

    var body: some View {
        VStack(spacing: 18) {
            Button(action: select) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(selected ? Theme.deepSpace : Theme.signal)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(selected ? AnyShapeStyle(Theme.visor)
                                               : AnyShapeStyle(Theme.hull.opacity(0.9)))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(Theme.label(18))
                            .foregroundStyle(selected ? Theme.warning : Theme.starlight)
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.starlight.opacity(0.55))
                    }

                    Spacer(minLength: 8)

                    ZStack {
                        Circle()
                            .strokeBorder(
                                selected ? Theme.beacon : Theme.starlight.opacity(0.3),
                                lineWidth: 2
                            )
                            .frame(width: 26, height: 26)
                        if selected {
                            Circle().fill(Theme.visor).frame(width: 14, height: 14)
                        }
                    }
                }
            }
            .pressable(scale: 0.96)

            if selected, !(Expanded.self == EmptyView.self) {
                expanded
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(selected ? Theme.steel.opacity(0.3) : Theme.hull.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    selected ? Theme.beacon.opacity(0.9) : Theme.starlight.opacity(0.12),
                    lineWidth: selected ? 1.8 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .lift(radius: 14, y: 7)
        .glow(Theme.beacon, radius: selected ? 16 : 0, strength: selected ? 0.55 : 0)
        .animation(Theme.bouncy, value: selected)
    }
}

#Preview {
    NavigationStack { GameSetupView(settings: GameSettings(), flow: GameFlow()) }
        .preferredColorScheme(.dark)
}
