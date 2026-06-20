import SwiftUI

/// Absumo's palette — "Mediterraneo": a sunlit, warm scheme of sand and
/// off-white surfaces, espresso ink, and accents drawn from the Italian
/// coast — terracotta, olive, and Adriatic blue. Calm and content-first;
/// the UI recedes so the Italian text is the hero.
enum Palette {
    // MARK: Surfaces (sunlit sand → off-white)
    static let sandTop  = Color(hex: 0xFBF4E6)   // lightest, top of the wash
    static let sand     = Color(hex: 0xF3E9D6)   // base warm sand
    static let sandLow  = Color(hex: 0xEADCC4)   // deeper, bottom of the wash
    static let card     = Color(hex: 0xFFFCF5)   // warm paper surface
    static let cardSoft = Color(hex: 0xFBF5E9)   // slightly recessed surface

    // MARK: Ink (warm espresso text)
    static let ink      = Color(hex: 0x2C2620)   // primary text
    static let inkSoft  = Color(hex: 0x6F6557)   // secondary text
    static let inkFaint = Color(hex: 0xA89C88)   // tertiary / disabled

    // MARK: Accents (the coast)
    static let terracotta     = Color(hex: 0xCC5A38)   // primary / brand action
    static let terracottaDeep = Color(hex: 0xA8401F)
    static let olive          = Color(hex: 0x6B7F3A)   // success / "correct"
    static let oliveDeep      = Color(hex: 0x4F6128)
    static let adriatic       = Color(hex: 0x2E7FA0)   // info / secondary accent
    static let adriaticDeep   = Color(hex: 0x1E5E78)
    static let rosso          = Color(hex: 0xC34330)   // error / streak
    static let rossoDeep      = Color(hex: 0x9A301F)

    /// Hairline borders and dividers on light surfaces.
    static let hairline = ink.opacity(0.10)

    /// The tricolore, restated in Mediterraneo tones (olive · cream · terracotta).
    static let tricolore = [olive, sandTop, terracotta]

    // MARK: Semantic aliases (kept so older call-sites stay valid)
    static let verde     = olive
    static let verdeDeep = oliveDeep
    static let bianco    = card

    /// Maps a unit's `accent` string to a colour along the coastal palette.
    static func accent(_ name: String) -> Color {
        switch name {
        case "rosso":  return terracotta
        case "bianco": return adriatic
        default:       return olive
        }
    }

    /// A two-stop gradient for a given accent (top-leading → bottom-trailing).
    static func gradient(_ c: Color) -> LinearGradient {
        LinearGradient(colors: [c, c.opacity(0.82)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Typography

extension Font {
    /// Warm serif display — used for the wordmark and the Italian prompts.
    static func serifDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
