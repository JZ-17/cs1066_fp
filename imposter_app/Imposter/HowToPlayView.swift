import SwiftUI

struct HowToPlayView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 34) {

                Text("How to Play")
                    .font(Theme.display(38))
                    .foregroundStyle(Theme.visor)
                    .glow(Theme.beacon, radius: 16)
                    .belowNavigationBar()

                Step(
                    number: 1,
                    title: "Everyone Gets Something",
                    detail: "Everyone gets the same secret word. Everyone except the imposter. They only see the category. That is enough to fake it, but never enough to be sure."
                ) {
                    RevealExample()
                }

                Step(
                    number: 2,
                    title: "Look in Private",
                    detail: "Tap your name. Read what you got. Pass the phone on. Nobody should see two screens."
                )

                Step(
                    number: 3,
                    title: "Say One Word",
                    detail: "Go around the circle. Each player says one word linked to the secret. Say too little and you look guilty. Say too much and the imposter gets it."
                )

                Step(
                    number: 4,
                    title: "Vote Out Loud",
                    detail: "Talk it out and vote at the table. The app stays out of this part. Pick wrong and the imposters win. Pick an imposter and they get one last guess."
                )

                Step(
                    number: 5,
                    title: "Reveal",
                    detail: "A caught imposter gets one try at the word. Get it right and they steal the win. Then tap Reveal to see the word and who was lying. Play Again takes you back to settings."
                )

                tip
                    .padding(.bottom, 44)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.backdrop }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .spaceBackButton()
    }

    private var tip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.warning)
            Text("Too hard on the imposter? Turn on Give Imposters a Hint in Game Settings. They get one clue word instead of just the category. Big group? Add a second imposter. By default they do not know each other, so they might accuse a teammate.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.starlight.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Theme.hull.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.warning.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - One numbered step

private struct Step<Extra: View>: View {

    let number: Int
    let title: String
    let detail: String
    @ViewBuilder var extra: Extra

    init(
        number: Int,
        title: String,
        detail: String,
        @ViewBuilder extra: () -> Extra = { EmptyView() }
    ) {
        self.number = number
        self.title = title
        self.detail = detail
        self.extra = extra()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(Theme.label(17))
                .foregroundStyle(Theme.deepSpace)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.visor))
                .glow(Theme.beacon, radius: 12, strength: 0.7)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(Theme.label(21))
                    .foregroundStyle(Theme.starlight)

                Text(detail)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.starlight.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)

                extra
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - The worked example under step one

private struct RevealExample: View {

    var body: some View {
        VStack(spacing: 10) {
            ExampleRow(name: "Alan", value: "Pizza", symbol: "🍕", isImposter: false)
            ExampleRow(name: "Logan", value: "Pizza", symbol: "🍕", isImposter: false)
            ExampleRow(name: "Josh", value: "Foods", symbol: "🕵️", isImposter: true)
        }
    }
}

private struct ExampleRow: View {

    let name: String
    let value: String
    let symbol: String
    let isImposter: Bool

    var body: some View {
        HStack {
            Text(name)
                .font(Theme.label(16))
                .foregroundStyle(Theme.starlight.opacity(0.6))

            Spacer(minLength: 12)

            Text(symbol)
                .font(.system(size: 16))
            Text(value)
                .font(Theme.label(16))
                .foregroundStyle(isImposter ? Theme.signal : Theme.starlight)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(isImposter ? Theme.alert.opacity(0.16) : Theme.hull.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(
                    isImposter ? Theme.alert.opacity(0.85) : Theme.starlight.opacity(0.12),
                    lineWidth: isImposter ? 1.5 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

#Preview {
    NavigationStack { HowToPlayView() }.preferredColorScheme(.dark)
}
