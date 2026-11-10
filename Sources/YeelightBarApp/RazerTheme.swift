import SwiftUI
import AppKit

// MARK: - Gamer-brand themes (Razer / Asus ROG / Asus TUF / Gigabyte Aorus)
// Each palette has a Light AND Dark value per colour, so every theme adapts to the macOS
// appearance (incl. the time-of-day "Auto" switch) — dark at night, light by day.

/// A colour with separate Light and Dark values — follows the system appearance.
private func dyn(_ light: (CGFloat, CGFloat, CGFloat), _ dark: (CGFloat, CGFloat, CGFloat)) -> Color {
    Color(nsColor: NSColor(name: nil) { ap in
        let isDark = ap.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let c = isDark ? dark : light
        return NSColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: 1)
    })
}

/// One brand's full palette. `accent` is the signature colour; the rest is the chrome.
struct ThemePalette {
    let accent, bg, bgTop, surface, text, secondary: Color
}

enum AppTheme: String, CaseIterable, Identifiable {
    case venom, crimson, forge, solar
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .venom:   return "Venom"
        case .crimson: return "Crimson"
        case .forge:   return "Forge"
        case .solar:   return "Solar"
        }
    }
    var swatch: Color { palette.accent }
    var palette: ThemePalette {
        switch self {
        case .venom:    // toxic neon green on a deep green-black chrome
            return ThemePalette(
                accent:     dyn((0.10, 0.52, 0.05), (0.30, 0.95, 0.25)),
                bg:         dyn((0.93, 0.965, 0.92), (0.039, 0.075, 0.043)),
                bgTop:      dyn((0.975, 0.995, 0.965), (0.060, 0.110, 0.066)),
                surface:    dyn((1.0, 1.0, 0.985), (0.071, 0.125, 0.078)),
                text:       dyn((0.08, 0.14, 0.07), (0.90, 0.98, 0.90)),
                secondary:  dyn((0.33, 0.45, 0.32), (0.56, 0.73, 0.55)))
        case .crimson:  // blood red on a deep red-black chrome
            return ThemePalette(
                accent:     dyn((0.78, 0.0, 0.12), (1.0, 0.22, 0.30)),
                bg:         dyn((0.975, 0.93, 0.94), (0.090, 0.035, 0.046)),
                bgTop:      dyn((0.99, 0.955, 0.965), (0.130, 0.052, 0.066)),
                surface:    dyn((1.0, 0.985, 0.99), (0.145, 0.060, 0.075)),
                text:       dyn((0.14, 0.07, 0.085), (0.98, 0.91, 0.92)),
                secondary:  dyn((0.45, 0.34, 0.36), (0.74, 0.57, 0.60)))
        case .forge:    // molten amber on a deep warm-black chrome
            return ThemePalette(
                accent:     dyn((0.60, 0.43, 0.0), (1.0, 0.74, 0.13)),
                bg:         dyn((0.975, 0.955, 0.90), (0.086, 0.066, 0.026)),
                bgTop:      dyn((0.995, 0.985, 0.945), (0.122, 0.097, 0.042)),
                surface:    dyn((1.0, 0.995, 0.955), (0.135, 0.108, 0.050)),
                text:       dyn((0.14, 0.11, 0.05), (0.98, 0.95, 0.87)),
                secondary:  dyn((0.45, 0.40, 0.29), (0.74, 0.68, 0.52)))
        case .solar:    // orange flare on a deep orange-black chrome
            return ThemePalette(
                accent:     dyn((0.82, 0.34, 0.0), (1.0, 0.50, 0.12)),
                bg:         dyn((0.98, 0.95, 0.91), (0.098, 0.052, 0.022)),
                bgTop:      dyn((0.995, 0.975, 0.93), (0.138, 0.078, 0.032)),
                surface:    dyn((1.0, 0.99, 0.945), (0.152, 0.088, 0.038)),
                text:       dyn((0.14, 0.10, 0.05), (0.98, 0.93, 0.87)),
                secondary:  dyn((0.46, 0.39, 0.30), (0.75, 0.64, 0.53)))
        }
    }
}

/// In-app light/dark override (independent of the macOS day/night switch). `auto` = follow the system.
enum AppAppearance: String, CaseIterable, Identifiable {
    case auto, light, dark
    var id: String { rawValue }
    var nsAppearance: NSAppearance? {
        switch self {
        case .auto:  return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark:  return NSAppearance(named: .darkAqua)
        }
    }
}

/// Holds the selected theme + appearance (persisted). Views observe it so changes apply app-wide live.
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var theme: AppTheme { didSet { UserDefaults.standard.set(theme.rawValue, forKey: "appTheme") } }
    @Published var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "appAppearance"); applyAppearance() }
    }
    private init() {
        let raw = UserDefaults.standard.string(forKey: "appTheme") ?? ""
        let migrate = ["razer": "venom", "rog": "crimson", "tuf": "forge", "aorus": "solar"]   // old brand keys → new
        theme = AppTheme(rawValue: migrate[raw] ?? raw) ?? .venom
        appearance = AppAppearance(rawValue: UserDefaults.standard.string(forKey: "appAppearance") ?? "") ?? .auto
    }
    /// Force the whole app's appearance (nil = follow macOS). Drives both the dyn() colours and SwiftUI's colorScheme.
    func applyAppearance() { NSApplication.shared.appearance = appearance.nsAppearance }
}

/// The colour API used across the app. Names are historical ("razer*"); each now resolves to the
/// SELECTED theme's palette, still dynamic for day/night.
extension Color {
    private static var pal: ThemePalette { ThemeManager.shared.theme.palette }
    static var razerGreen: Color     { pal.accent }
    static var razerBG: Color        { pal.bg }
    static var razerBGTop: Color     { pal.bgTop }
    static var razerSurface: Color   { pal.surface }
    static var razerText: Color      { pal.text }
    static var razerSecondary: Color { pal.secondary }
    static var razerHairline: Color  { pal.accent.opacity(0.30) }
}

/// Shared optical tint. Views use the same sample regardless of their position in the app.
struct GlassLight {
    var color: Color
    var palette: [Color] = []
    var rotation: Double = 0

    var reflections: [Color] {
        [color] + (palette.isEmpty ? [color, color] : Array(palette.prefix(8)))
    }
}

private struct GlassLightKey: EnvironmentKey {
    static var defaultValue: GlassLight { GlassLight(color: .razerGreen) }
}

private extension EnvironmentValues {
    var glassLight: GlassLight {
        get { self[GlassLightKey.self] }
        set { self[GlassLightKey.self] = newValue }
    }
}

struct RazerBackground: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.glassLight) private var light

    var body: some View {
        let dark = scheme == .dark
        ZStack {
            (dark ? Color(white: 0.077) : Color(white: 0.95))
            RadialGradient(colors: [light.color.opacity(dark ? 0.16 : 0.10), .clear],
                           center: .topTrailing, startRadius: 4, endRadius: 480)
            Canvas { ctx, size in
                var dots = Path()
                for x in stride(from: 8.0, to: size.width, by: 12) {
                    for y in stride(from: 8.0, to: size.height, by: 12) {
                        dots.addEllipse(in: CGRect(x: x, y: y, width: 1, height: 1))
                    }
                }
                ctx.fill(dots, with: .color(dark ? .white.opacity(0.08) : .black.opacity(0.08)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .ignoresSafeArea()
    }
}

private struct RGBGlass: ViewModifier {
    var radius: CGFloat
    var prominent: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.glassLight) private var light

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let dark = scheme == .dark
        let bright = prominent ? 0.96 : 0.70
        let reflections = light.reflections.flatMap { tint in
            [tint.opacity(bright), tint.opacity(0.10)]
        }
        let spectrum = AngularGradient(colors: reflections + Array(reflections.prefix(1)),
                                       center: .center, angle: .degrees(reduceMotion ? 0 : light.rotation))
        return content
            .background {
                if reduceTransparency {
                    shape.fill(dark ? Color(white: 0.13) : .white)
                } else {
                    if prominent { shape.fill(.regularMaterial) }
                    shape.fill(dark ? Color(white: 0.11).opacity(0.88) : .white.opacity(0.87))
                    shape.fill(RadialGradient(colors: [light.color.opacity(prominent ? 0.23 : 0.13), .clear],
                                              center: .topLeading, startRadius: 0, endRadius: 200))
                }
            }
            .overlay {
                ZStack {
                    if !reduceTransparency {
                        shape.strokeBorder(spectrum, lineWidth: prominent ? 5 : 3)
                            .opacity(0.22)
                    }
                    shape.strokeBorder(spectrum, lineWidth: prominent ? 1.5 : 1)
                    shape.inset(by: 2).strokeBorder(
                        LinearGradient(colors: [.white.opacity(dark ? 0.19 : 0.85), .clear, .white.opacity(0.10)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
    }
}

struct RazerGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            configuration.label
                .font(.headline)
                .foregroundStyle(.primary)
            configuration.content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .rgbGlass(radius: 17)
    }
}

/// Pulsing green glow for "live/active" elements.
struct RazerPulse: ViewModifier {
    var active: Bool
    var color: Color = .razerGreen
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .shadow(color: active ? color.opacity(on ? 0.85 : 0.2) : .clear, radius: active ? (on ? 11 : 4) : 0)
            .onAppear { pulse() }
            .onChange(of: active) { _ in pulse() }
    }
    private func pulse() {
        on = false
        guard active else { return }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { on = true }
    }
}

struct YeelightBrandMark: View {
    var size: CGFloat = 20
    private static let logo = Bundle.main.url(forResource: "YeelightLogo", withExtension: "png")
        .flatMap { NSImage(contentsOf: $0) }

    var body: some View {
        Group {
            if let logo = Self.logo {
                Image(nsImage: logo).resizable().scaledToFit()
            }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}

struct GlassWordmark: View {
    var logoSize: CGFloat = 20
    var textSize: CGFloat = 14

    var body: some View {
        HStack(spacing: 8) {
            YeelightBrandMark(size: logoSize)
            Text(verbatim: "YEELIGHT")
                .font(.system(size: textSize, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.primary)
        }
    }
}

extension View {
    /// A section / hero heading in the Razer style: heavy, uppercase, tracked.
    func razerHeading(_ size: CGFloat = 13) -> some View {
        self.font(.system(size: size, weight: .heavy))
            .textCase(.uppercase).tracking(1.4)
            .foregroundStyle(Color.razerText)
    }

    /// Compact glass readout; the shared lighting colours the rim and the text stays legible.
    func razerHUD() -> some View {
        self.font(.system(size: 11, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .rgbGlass(radius: 6)
    }

    func razerPulse(_ active: Bool, color: Color = .razerGreen) -> some View { modifier(RazerPulse(active: active, color: color)) }

    /// Apply the Razer look — green accent + panel style. Follows the system Light/Dark/Auto theme.
    func rgbGlass(radius: CGFloat = 14, prominent: Bool = false) -> some View {
        modifier(RGBGlass(radius: radius, prominent: prominent))
    }

    func razerChrome(light: GlassLight) -> some View {
        self.tint(.razerGreen).groupBoxStyle(RazerGroupBoxStyle())
            .environment(\.glassLight, light)
    }
}
