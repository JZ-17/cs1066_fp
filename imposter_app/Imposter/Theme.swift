import SwiftUI

/// Visual language for the app: International Orange (the colour the Golden
/// Gate Bridge is actually painted) over a deep fog-purple dusk, with warm
/// glows and heavy soft shadows.
enum Theme {

    // MARK: Palette

    static let inkDeep = Color(hex: 0x140A1E)   // near-black plum
    static let ink = Color(hex: 0x2A1030)       // dusk purple
    static let fog = Color(hex: 0x5B2A52)       // muted violet haze
    static let crimson = Color(hex: 0xA32330)   // deep bridge red
    static let orange = Color(hex: 0xE04A1F)    // International Orange
    static let ember = Color(hex: 0xFF7A3D)     // lit edge
    static let amber = Color(hex: 0xFFB347)     // sun highlight
    static let cream = Color(hex: 0xFFF3E4)     // warm white text

    // MARK: Gradients

    /// Full-screen dusk: deep plum at the top falling to a burning horizon.
    static var dusk: LinearGradient {
        LinearGradient(
            colors: [inkDeep, ink, fog.opacity(0.85), crimson.opacity(0.75)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// The warm sweep used on titles and primary buttons.
    static var sunset: LinearGradient {
        LinearGradient(
            colors: [amber, ember, orange, crimson],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Soft radial bloom placed behind focal elements.
    static func bloom(_ color: Color, opacity: Double = 0.55) -> RadialGradient {
        RadialGradient(
            colors: [color.opacity(opacity), color.opacity(0)],
            center: .center,
            startRadius: 1,
            endRadius: 260
        )
    }

    // MARK: Backdrop

    /// Dusk gradient with the horizon glow burning at the bottom.
    ///
    /// Always attach this with `.background { Theme.backdrop }` rather than as
    /// a ZStack layer. The glow circle is far wider than a phone screen, and a
    /// ZStack sizes itself to its largest child — which silently stretches the
    /// whole layout. A background never contributes to its parent's size.
    static var backdrop: some View {
        ZStack {
            Theme.dusk
            VStack {
                Spacer()
                Circle()
                    .fill(Theme.bloom(Theme.orange, opacity: 0.45))
                    .frame(width: 640, height: 640)
                    .blur(radius: 30)
                    .offset(y: 240)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: Type

    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Shadow stacks

extension View {
    /// Layered glow: a tight bright core plus a wide soft halo. Two shadows
    /// read far better than one big blurry one.
    func glow(_ color: Color = Theme.orange, radius: CGFloat = 18, strength: Double = 1) -> some View {
        self
            .shadow(color: color.opacity(0.55 * strength), radius: radius * 0.45, y: 0)
            .shadow(color: color.opacity(0.35 * strength), radius: radius, y: radius * 0.3)
            .shadow(color: color.opacity(0.18 * strength), radius: radius * 2.2, y: radius * 0.5)
    }

    /// Depth shadow for raised surfaces, warm rather than neutral grey.
    func lift(radius: CGFloat = 20, y: CGFloat = 12) -> some View {
        self
            .shadow(color: Theme.inkDeep.opacity(0.55), radius: radius, y: y)
            .shadow(color: Theme.crimson.opacity(0.25), radius: radius * 1.6, y: y * 1.4)
    }
}

// MARK: - Navigation clearance

extension View {
    /// Screens here hide the navigation bar's background, so content scrolls
    /// underneath it. Big custom titles need to clear the Back button.
    func belowNavigationBar() -> some View {
        padding(.top, 48)
    }
}

// MARK: - Hex helper

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
