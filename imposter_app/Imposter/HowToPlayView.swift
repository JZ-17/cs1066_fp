import SwiftUI

struct HowToPlayView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 34) {

                Text("How to Play")
                    .font(Theme.display(38))
                    .foregroundStyle(Theme.sunset)
                    .glow(Theme.orange, radius: 16)
                    .belowNavigationBar()

                Step(
                    number: 1,
                    title: "Everyone Gets Something",
                    detail: "The group all see the same secret word. The imposter sees only the category it came from — enough to bluff, never enough to be sure."
                ) {
                    RevealExample()
                }

                Step(
                    number: 2,
                    title: "Look in Private",
                    detail: "Tap your name, read what you were given, then hand the phone to the next player. Nobody should see two screens."
                )

                Step(
                    number: 3,
                    title: "Say One Word",
                    detail: "Go around the circle. Each player says a single word connected to the secret. Say too little and you look suspicious; say too much and you hand it to the imposter."
                )

                Step(
                    number: 4,
                    title: "Vote Out Loud",
                    detail: "Talk it out and vote around the table — the app stays out of this part. Land on an innocent and the imposters take the round. Land on an imposter, any imposter, even with others still hiding, and they get one last guess."
                )

                Step(
                    number: 5,
                    title: "Reveal",
                    detail: "A caught imposter gets one shot at naming the word — land it and they steal the win anyway. Then tap Reveal to see the word and who was lying, and Play Again drops you straight back into settings."
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
    }

    private var tip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.amber)
            Text("Too hard on the imposter? Turn on Give Imposters a Hint in Game Settings and they draw a single clue word instead of just the category. Playing with a big group? Add a second imposter. They play blind by default, so they do not know who each other are and may well accuse a teammate.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.cream.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Theme.ink.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.amber.opacity(0.3), lineWidth: 1)
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
                .foregroundStyle(Theme.inkDeep)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.sunset))
                .glow(Theme.orange, radius: 12, strength: 0.7)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(Theme.label(21))
                    .foregroundStyle(Theme.cream)

                Text(detail)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.cream.opacity(0.65))
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
                .foregroundStyle(Theme.cream.opacity(0.6))

            Spacer(minLength: 12)

            Text(symbol)
                .font(.system(size: 16))
            Text(value)
                .font(Theme.label(16))
                .foregroundStyle(isImposter ? Theme.ember : Theme.cream)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(isImposter ? Theme.crimson.opacity(0.16) : Theme.ink.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(
                    isImposter ? Theme.orange.opacity(0.75) : Theme.cream.opacity(0.12),
                    lineWidth: isImposter ? 1.5 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

#Preview {
    NavigationStack { HowToPlayView() }.preferredColorScheme(.dark)
}
