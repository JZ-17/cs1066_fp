import SwiftUI

/// Studio intro: the sky fades up, J, A and L light in sequence, a crew member
/// tumbles slowly past the wordmark, and a task bar fills before the whole
/// thing hands off to the home screen.
struct LoadingView: View {

    var onFinished: () -> Void

    private let letters = ["J", "A", "L"]

    @State private var revealed = -1      // index of the last letter shown
    @State private var haloScale: CGFloat = 0.6
    @State private var haloOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var progress: Double = 0
    @State private var barOpacity: Double = 0
    @State private var drift: Double = -0.2
    @State private var tumble: Double = -18
    @State private var skyOpacity: Double = 0

    var body: some View {
        ZStack {
            Theme.space.ignoresSafeArea()

            Starfield()
                .opacity(skyOpacity)
                .ignoresSafeArea()

            // Cold bloom behind the wordmark.
            Circle()
                .fill(Theme.bloom(Theme.beacon, opacity: 0.42))
                .frame(width: 520, height: 520)
                .scaleEffect(haloScale)
                .opacity(haloOpacity)
                .blur(radius: 20)

            VStack(spacing: 22) {
                ZStack {
                    HStack(spacing: 6) {
                        ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                            Text(letter)
                                .font(Theme.display(84))
                                .foregroundStyle(Theme.visor)
                                .glow(Theme.signal, radius: 26, strength: index <= revealed ? 1 : 0)
                                .opacity(index <= revealed ? 1 : 0)
                                .blur(radius: index <= revealed ? 0 : 14)
                                .offset(y: index <= revealed ? 0 : 26)
                                .scaleEffect(index <= revealed ? 1 : 0.82)
                        }
                    }

                    // A crew member tumbling slowly past the mark.
                    GeometryReader { geo in
                        CrewFigure(tint: Theme.beacon, size: 40)
                            .rotationEffect(.degrees(tumble))
                            .position(
                                x: drift * (geo.size.width + 120) - 60,
                                y: geo.size.height * 0.24
                            )
                    }
                    .allowsHitTesting(false)
                }
                .frame(height: 118)

                TaskBar(progress: progress, height: 14)
                    .frame(width: 200)
                    .opacity(barOpacity)

                Text("PRESENTS")
                    .font(Theme.label(13))
                    .tracking(8)
                    .foregroundStyle(Theme.starlight.opacity(0.75))
                    .opacity(taglineOpacity)
            }
        }
        .task { await runIntro() }
        // Let an impatient viewer skip ahead.
        .contentShape(Rectangle())
        .onTapGesture { onFinished() }
    }

    private func runIntro() async {
        withAnimation(.easeOut(duration: 2.1)) { skyOpacity = 1 }
        withAnimation(.easeOut(duration: 1.5)) {
            haloOpacity = 1
            haloScale = 1
        }

        // One slow pass across the screen, started up front so the drift is
        // already under way by the time the letters land.
        withAnimation(.linear(duration: 6.2)) {
            drift = 1.2
            tumble = 342
        }

        for index in letters.indices {
            try? await Task.sleep(for: .milliseconds(430))
            withAnimation(.spring(response: 0.72, dampingFraction: 0.66)) {
                revealed = index
            }
        }

        try? await Task.sleep(for: .milliseconds(300))
        withAnimation(.easeOut(duration: 0.45)) { barOpacity = 1 }
        withAnimation(.easeInOut(duration: 1.7)) { progress = 1 }
        withAnimation(.easeIn(duration: 0.7).delay(0.25)) { taglineOpacity = 1 }

        try? await Task.sleep(for: .milliseconds(1_900))
        onFinished()
    }
}

#Preview {
    LoadingView(onFinished: {})
}
