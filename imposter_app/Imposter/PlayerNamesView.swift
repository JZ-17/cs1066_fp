import SwiftUI

struct PlayerNamesView: View {

    @Bindable var settings: GameSettings
    @Bindable var flow: GameFlow
    @FocusState private var focused: Int?

    var body: some View {
        ZStack {
            Theme.space.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {

                        Text("Player Names")
                            .font(Theme.display(32))
                            .foregroundStyle(Theme.visor)
                            .glow(Theme.beacon, radius: 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .belowNavigationBar()
                            .padding(.bottom, 6)

                        countBanner

                        ForEach(Array(settings.playerNames.enumerated()), id: \.offset) { index, _ in
                            PlayerRow(
                                index: index,
                                name: Binding(
                                    get: { settings.name(at: index) },
                                    set: { settings.setName($0, at: index) }
                                ),
                                focus: $focused,
                                canRemove: settings.playerCount > GameSettings.playerRange.lowerBound,
                                remove: { withAnimation(Theme.bouncy) { settings.removePlayer(at: index) } },
                                submit: {
                                    focused = index + 1 < settings.playerCount ? index + 1 : nil
                                }
                            )
                            .transition(.softSwap)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .containerRelativeFrame(.horizontal) { width, _ in min(width, 560) }
                }
                .scrollDismissesKeyboard(.interactively)

                actionBar

                Button {
                    flow.startRound(settings: settings)
                } label: {
                    Label(
                        settings.canStart ? "Start Game" : "Pick a Deck First",
                        systemImage: settings.canStart ? "play.fill" : "rectangle.stack"
                    )
                        .font(Theme.label(19))
                        .foregroundStyle(settings.canStart ? Theme.deepSpace : Theme.starlight.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background {
                            if settings.canStart {
                                Theme.visor
                            } else {
                                Theme.hull.opacity(0.7)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .glow(Theme.beacon, radius: 20, strength: settings.canStart ? 0.85 : 0)
                }
                .pressable()
                .disabled(!settings.canStart)
                .padding(.horizontal, 22)
                .padding(.bottom, 14)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .background(Theme.deepSpace.opacity(0.75))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .spaceBackButton()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
                    .font(Theme.label(17))
                    .foregroundStyle(Theme.signal)
            }
        }
    }

    private var countBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.deepSpace)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Theme.visor)
                )

            Text("\(settings.playerCount) Players")
                .font(Theme.label(20))
                .foregroundStyle(Theme.starlight)
                .contentTransition(.numericText())
                .animation(Theme.quick, value: settings.playerCount)

            Spacer()

            Text("\(GameSettings.playerRange.lowerBound)–\(GameSettings.playerRange.upperBound)")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.starlight.opacity(0.55))
        }
        .padding(16)
        .background(Theme.steel.opacity(0.28))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.beacon.opacity(0.65), lineWidth: 1.4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .lift(radius: 14, y: 7)
        .padding(.bottom, 4)
    }

    private var actionBar: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(Theme.bouncy) { settings.removePlayer() }
            } label: {
                barLabel("person.badge.minus", "Remove", tint: Theme.alert)
            }
            .pressable(scale: 0.95, dims: true)
            .disabled(settings.playerCount <= GameSettings.playerRange.lowerBound)
            .opacity(settings.playerCount <= GameSettings.playerRange.lowerBound ? 0.4 : 1)

            Button {
                withAnimation(Theme.bouncy) { settings.addPlayer() }
            } label: {
                barLabel("person.badge.plus", "Add", tint: Theme.beacon)
            }
            .pressable(scale: 0.95, dims: true)
            .disabled(settings.playerCount >= GameSettings.playerRange.upperBound)
            .opacity(settings.playerCount >= GameSettings.playerRange.upperBound ? 0.4 : 1)
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .containerRelativeFrame(.horizontal) { width, _ in min(width, 560) }
        .background(Theme.deepSpace.opacity(0.75))
    }

    private func barLabel(_ icon: String, _ title: String, tint: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
            Text(title)
                .font(Theme.label(18))
        }
        .foregroundStyle(tint == Theme.beacon ? Theme.warning : Theme.signal)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tint.opacity(0.85), lineWidth: 1.6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// One editable row: position badge, name field, and a remove button.
struct PlayerRow: View {

    let index: Int
    @Binding var name: String
    var focus: FocusState<Int?>.Binding
    let canRemove: Bool
    let remove: () -> Void
    let submit: () -> Void

    private var isEditing: Bool { focus.wrappedValue == index }

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index + 1)")
                .font(Theme.label(19))
                .foregroundStyle(Theme.deepSpace)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.visor)
                )

            TextField("", text: $name, prompt: Text("Player \(index + 1)")
                .foregroundColor(Theme.starlight.opacity(0.35)))
                .font(Theme.label(18))
                .foregroundStyle(Theme.starlight)
                .tint(Theme.signal)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused(focus, equals: index)
                .onSubmit(submit)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Theme.deepSpace.opacity(isEditing ? 0.75 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isEditing ? Theme.beacon.opacity(0.9) : Theme.starlight.opacity(0.18),
                            lineWidth: isEditing ? 2 : 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .animation(Theme.quick, value: isEditing)

            Button(action: remove) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(canRemove ? Theme.starlight.opacity(0.6) : Theme.starlight.opacity(0.2))
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .pressable(scale: 0.85, dims: true)
            .disabled(!canRemove)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.hull.opacity(isEditing ? 0.7 : 0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.starlight.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .lift(radius: 10, y: 5)
    }
}

#Preview {
    NavigationStack { PlayerNamesView(settings: GameSettings(), flow: GameFlow()) }
        .preferredColorScheme(.dark)
}
