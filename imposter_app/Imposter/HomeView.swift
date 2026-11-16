import SwiftUI

struct HomeView: View {

    @State private var appeared = false
    @State private var settings = GameSettings()
    @State private var flow = GameFlow()

    var body: some View {
        NavigationStack(path: $flow.path) {
                  ScrollView {
                    VStack(spacing: 0) {
                        header
                            .padding(.top, 52)
                            .padding(.bottom, 44)

                        VStack(spacing: 16) {
                            Button {
                                flow.newGame()
                            } label: {
                                MenuCardFace(
                                    icon: "play.fill",
                                    title: "New Game",
                                    subtitle: "Gather everyone and pass the phone",
                                    prominent: true
                                )
                            }
                            .buttonStyle(PressableCard())

                            MenuCard(
                                icon: "rectangle.stack.fill",
                                title: "Decks",
                                subtitle: "Browse, edit, or generate a new one"
                            )
                            NavigationLink {
                                HowToPlayView()
                            } label: {
                                MenuCardFace(
                                    icon: "questionmark.circle.fill",
                                    title: "How to Play",
                                    subtitle: "Rules, roles, and a sample round"
                                )
                            }
                            .buttonStyle(PressableCard())
                            MenuCard(
                                icon: "gearshape.fill",
                                title: "Settings",
                                subtitle: "Players, timer, and sign-in"
                            )
                        }
                        .padding(.horizontal, 24)
                        .frame(maxWidth: 520)          // keeps iPad from stretching
                        .padding(.bottom, 48)
                    }
                    .frame(maxWidth: .infinity)
                  }
                  .background { Theme.backdrop }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .setup:
                    GameSetupView(settings: settings, flow: flow)
                case .decks:
                    DeckPickerView(settings: settings)
                case .names:
                    PlayerNamesView(settings: settings, flow: flow)
                case .round:
                    if let round = flow.round {
                        RoundFlowView(round: round, flow: flow)
                    }
                }
            }
        }
        .tint(Theme.ember)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 18)
        .task {
            withAnimation(.easeOut(duration: 0.65)) { appeared = true }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            Text("IMPOSTER")
                .font(Theme.display(52))
                .tracking(2)
                .foregroundStyle(Theme.sunset)
                .glow(Theme.orange, radius: 24)

            Text("One of you is bluffing.")
                .font(Theme.label(16))
                .foregroundStyle(Theme.cream.opacity(0.78))
        }
    }
}

/// Menu row for destinations that are not built yet.
struct MenuCard: View {
    let icon: String
    let title: String
    var subtitle: String = ""
    var prominent: Bool = false

    var body: some View {
        Button {
            // Screens land in later tasks.
        } label: {
            MenuCardFace(icon: icon, title: title, subtitle: subtitle, prominent: prominent)
        }
        .buttonStyle(PressableCard())
    }
}

/// The visual body of a menu row, shared by buttons and navigation links.
struct MenuCardFace: View {

    let icon: String
    let title: String
    var subtitle: String = ""
    var prominent: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(prominent ? Theme.inkDeep : Theme.ember)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(prominent ? Theme.cream.opacity(0.9) : Theme.ink.opacity(0.85))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.label(19))
                    .foregroundStyle(prominent ? Theme.inkDeep : Theme.cream)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            prominent ? Theme.inkDeep.opacity(0.7) : Theme.cream.opacity(0.6)
                        )
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(
                    prominent ? Theme.inkDeep.opacity(0.55) : Theme.cream.opacity(0.35)
                )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.cream.opacity(prominent ? 0.35 : 0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .lift(radius: prominent ? 26 : 16, y: prominent ? 14 : 8)
        .glow(Theme.orange, radius: prominent ? 22 : 0, strength: prominent ? 0.8 : 0)
    }

    @ViewBuilder
    private var background: some View {
        if prominent {
            Theme.sunset
        } else {
            Theme.ink.opacity(0.55)
        }
    }
}

/// Shrinks a card slightly while it is held.
struct PressableCard: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    HomeView().preferredColorScheme(.dark)
}
