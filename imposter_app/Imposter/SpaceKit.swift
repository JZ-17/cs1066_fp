import SwiftUI

// MARK: - Star field

/// Stars scattered over the backdrop, a handful of them breathing.
///
/// The positions come from a seeded generator held in a `static let`, so they
/// are computed once and stay put. Calling `Double.random` in `body` would
/// reshuffle the whole sky on every redraw.
struct Starfield: View {

    var count: Int = 64
    var drifts: Bool = true

    @State private var breathing = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Self.sky) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .opacity(star.alpha * (breathing ? star.dim : 1))
                        .position(
                            x: star.x * geo.size.width,
                            y: star.y * geo.size.height
                        )
                        .animation(
                            .easeInOut(duration: star.period)
                            .repeatForever(autoreverses: true)
                            .delay(star.delay),
                            value: breathing
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { if drifts { breathing = true } }
    }

    // MARK: The sky itself

    struct Star: Identifiable {
        let id: Int
        let x: Double
        let y: Double
        let size: Double
        let alpha: Double
        let dim: Double
        let period: Double
        let delay: Double
    }

    /// 64 stars, generated once from a fixed seed.
    private static let sky: [Star] = {
        var rng = Seeded(seed: 0x5EED_1066)
        return (0..<64).map { index in
            let bright = rng.next(in: 0.25...0.95)
            return Star(
                id: index,
                x: rng.next(in: 0.02...0.98),
                y: rng.next(in: 0.0...1.0),
                // A few big ones carry the depth; most stay pinpricks.
                size: rng.next(in: 1.0...1.0) + (rng.next(in: 0...1) > 0.86 ? 1.8 : 0.4),
                alpha: bright,
                dim: rng.next(in: 0.25...0.7),
                period: rng.next(in: 1.6...4.2),
                delay: rng.next(in: 0...2.4)
            )
        }
    }()
}

/// A tiny linear congruential generator. `SystemRandomNumberGenerator` would
/// give a different sky on every launch; this gives the same one every time,
/// which matters because the field is cached in a `static let`.
private struct Seeded {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        let unit = Double(state >> 11) / Double(UInt64.max >> 11)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
}

// MARK: - Crew figure

/// A suited figure, drawn entirely from primitives.
///
/// Deliberately its own design, a round helmet over a tapered suit, rather
/// than a copy of any existing game's character. See the note in Theme.
struct CrewFigure: View {

    var tint: Color = Theme.beacon
    var size: CGFloat = 64
    /// Imposters get a visor you cannot read.
    var sinister: Bool = false

    var body: some View {
        ZStack {
            // Backpack tank
            Capsule()
                .fill(tint.opacity(0.55))
                .frame(width: size * 0.26, height: size * 0.46)
                .offset(x: -size * 0.38, y: size * 0.06)

            // Suit
            VStack(spacing: -size * 0.04) {
                RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.68)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.74, height: size * 0.82)

                // Boots
                HStack(spacing: size * 0.1) {
                    Capsule().fill(tint.opacity(0.8)).frame(width: size * 0.24, height: size * 0.18)
                    Capsule().fill(tint.opacity(0.8)).frame(width: size * 0.24, height: size * 0.18)
                }
            }

            // Visor
            Capsule()
                .fill(
                    sinister
                        ? LinearGradient(
                            colors: [Theme.alert.opacity(0.9), Theme.deepSpace],
                            startPoint: .top,
                            endPoint: .bottom
                          )
                        : LinearGradient(
                            colors: [Theme.starlight, Theme.signal.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                          )
                )
                .frame(width: size * 0.42, height: size * 0.26)
                .overlay(
                    // Specular highlight along the top of the glass
                    Capsule()
                        .fill(Color.white.opacity(0.75))
                        .frame(width: size * 0.14, height: size * 0.06)
                        .offset(x: -size * 0.07, y: -size * 0.05)
                )
                .offset(x: size * 0.08, y: -size * 0.16)
        }
        .frame(width: size, height: size)
        .glow(sinister ? Theme.alert : tint, radius: size * 0.3, strength: 0.7)
    }
}

// MARK: - Task bar

/// The progress bar used while something is working. Reads as a ship readout:
/// a stroked track with a glowing fill and a notch pattern behind it.
struct TaskBar: View {

    /// 0 to 1.
    var progress: Double
    var height: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.deepSpace.opacity(0.85))

                // Segment ticks, so a part-full bar still reads as a readout.
                HStack(spacing: 0) {
                    ForEach(0..<12, id: \.self) { _ in
                        Rectangle()
                            .fill(Theme.starlight.opacity(0.05))
                            .frame(width: 1)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.horizontal, height * 0.3)

                Capsule()
                    .fill(Theme.visor)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
                    .glow(Theme.beacon, radius: height, strength: 0.8)
            }
            .overlay(
                Capsule().strokeBorder(Theme.starlight.opacity(0.22), lineWidth: 1.2)
            )
            .clipShape(Capsule())
        }
        .frame(height: height)
    }
}

// MARK: - Inline loading indicator

/// A crew figure bobbing along a task bar, for work that takes a moment.
/// Generating a deck, say. It drives itself. Just show it while you are busy.
struct CrewLoader: View {

    var label: String
    var tint: Color = Theme.beacon

    @State private var walk: Double = 0
    @State private var bob = false

    var body: some View {
        VStack(spacing: 18) {
            GeometryReader { geo in
                CrewFigure(tint: tint, size: 44)
                    .offset(y: bob ? -5 : 5)
                    .animation(
                        .easeInOut(duration: 0.42).repeatForever(autoreverses: true),
                        value: bob
                    )
                    // Travels the width of the bar below it.
                    .position(
                        x: 22 + walk * max(0, geo.size.width - 44),
                        y: geo.size.height / 2
                    )
            }
            .frame(height: 54)

            TaskBar(progress: walk)

            Text(label)
                .font(Theme.label(14))
                .tracking(2)
                .foregroundStyle(Theme.starlight.opacity(0.7))
                .contentTransition(.opacity)
        }
        .onAppear {
            bob = true
            // Indeterminate: sweeps the bar, then starts over.
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false)) {
                walk = 1
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        HStack(spacing: 24) {
            CrewFigure(tint: Theme.beacon)
            CrewFigure(tint: Theme.alert, sinister: true)
            CrewFigure(tint: Theme.warning)
        }
        TaskBar(progress: 0.45).padding(.horizontal, 40)
        CrewLoader(label: "BUILDING DECK").padding(.horizontal, 40)
    }
    .padding()
    .background { Theme.backdrop }
}

// MARK: - Transition cover

/// Full-screen cover shown while the navigation stack is rewound.
///
/// Both exits from a finished round pop several levels at once, which
/// `NavigationStack` otherwise renders as a hard cut with the intermediate
/// screens flashing past. This hides the swap and gives it a beat of its own:
/// the sky dims, a crew member drifts through, and a bar sweeps under a label.
struct AirlockCover: View {

    let title: String

    @State private var sweep: Double = 0
    @State private var drift: Double = -0.25
    @State private var tumble: Double = 0
    @State private var glow: Double = 0.4

    var body: some View {
        ZStack {
            Theme.deepSpace.opacity(0.97)
            Starfield(drifts: false)

            Circle()
                .fill(Theme.bloom(Theme.beacon, opacity: 0.4))
                .frame(width: 460, height: 460)
                .blur(radius: 24)
                .scaleEffect(glow)

            GeometryReader { geo in
                CrewFigure(tint: Theme.beacon, size: 46)
                    .rotationEffect(.degrees(tumble))
                    .position(
                        x: drift * (geo.size.width + 140) - 70,
                        y: geo.size.height * 0.42
                    )
            }

            VStack(spacing: 16) {
                Spacer()
                Text(title)
                    .font(Theme.label(13))
                    .tracking(6)
                    .foregroundStyle(Theme.starlight.opacity(0.75))

                TaskBar(progress: sweep, height: 10)
                    .frame(width: 180)
                Spacer()
                    .frame(height: 120)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.75)) {
                sweep = 1
                glow = 1
            }
            withAnimation(.linear(duration: 1.1)) {
                drift = 1.25
                tumble = 190
            }
        }
    }
}

// MARK: - Back button

/// Replaces the system back chevron with something that belongs to the rest
/// of the app: a lit ring with a glow, rather than a thin blue arrow.
///
/// It calls `dismiss()`, so it behaves exactly like the button it replaces and
/// the swipe-from-edge gesture keeps working.
struct SpaceBackButton: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(Theme.signal)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(Theme.hull.opacity(0.8))
                )
                .overlay(
                    Circle().strokeBorder(Theme.beacon.opacity(0.55), lineWidth: 1.3)
                )
                // A toolbar item clips to its own bounds, so a wide halo comes
                // out as a square. One tight shadow, with padding around it to
                // land inside the clip.
                .shadow(color: Theme.beacon.opacity(0.45), radius: 4)
                .padding(5)
                // The glyph alone is a tiny tap target. The circle is the
                // button as far as the finger is concerned.
                .contentShape(Circle())
        }
        .pressable(scale: 0.88, dims: true)
        .accessibilityLabel("Back")
    }
}

extension View {
    /// Hides the system back button and puts ours in its place.
    ///
    /// Do not use on a screen that sets `navigationBarBackButtonHidden`
    /// conditionally, such as the round, where going back mid game would be
    /// wrong. This always hides it.
    func spaceBackButton() -> some View {
        navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SpaceBackButton()
                }
            }
    }
}
