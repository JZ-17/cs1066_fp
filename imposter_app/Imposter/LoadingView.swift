import SwiftUI

/// Studio-style intro: J, A and L rise and ignite in sequence, a rule draws
/// beneath them, then the whole thing hands off to the home screen.
struct LoadingView: View {

    var onFinished: () -> Void

    private let letters = ["J", "A", "L"]

    @State private var revealed = -1      // index of the last letter shown
    @State private var ruleWidth: CGFloat = 0
    @State private var haloScale: CGFloat = 0.6
    @State private var haloOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            Theme.dusk.ignoresSafeArea()

            // Warm bloom behind the wordmark.
            Circle()
                .fill(Theme.bloom(Theme.orange, opacity: 0.5))
                .frame(width: 520, height: 520)
                .scaleEffect(haloScale)
                .opacity(haloOpacity)
                .blur(radius: 20)

            VStack(spacing: 22) {
                HStack(spacing: 6) {
                    ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                        Text(letter)
                            .font(Theme.display(84))
                            .foregroundStyle(Theme.sunset)
                            .glow(Theme.ember, radius: 26, strength: index <= revealed ? 1 : 0)
                            .opacity(index <= revealed ? 1 : 0)
                            .blur(radius: index <= revealed ? 0 : 14)
                            .offset(y: index <= revealed ? 0 : 26)
                            .scaleEffect(index <= revealed ? 1 : 0.82)
                    }
                }

                // Rule that draws out from the centre once the letters land.
                Capsule()
                    .fill(Theme.sunset)
                    .frame(width: ruleWidth, height: 3)
                    .glow(Theme.orange, radius: 12)

                Text("PRESENTS")
                    .font(Theme.label(13))
                    .tracking(8)
                    .foregroundStyle(Theme.cream.opacity(0.75))
                    .opacity(taglineOpacity)
            }
        }
        .task { await runIntro() }
        // Let an impatient viewer skip ahead.
        .contentShape(Rectangle())
        .onTapGesture { onFinished() }
    }

    private func runIntro() async {
        withAnimation(.easeOut(duration: 1.1)) {
            haloOpacity = 1
            haloScale = 1
        }

        for index in letters.indices {
            try? await Task.sleep(for: .milliseconds(260))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
                revealed = index
            }
        }

        try? await Task.sleep(for: .milliseconds(240))
        withAnimation(.easeOut(duration: 0.5)) { ruleWidth = 184 }
        withAnimation(.easeIn(duration: 0.5).delay(0.15)) { taglineOpacity = 1 }

        try? await Task.sleep(for: .milliseconds(900))
        onFinished()
    }
}

#Preview {
    LoadingView(onFinished: {})
}
