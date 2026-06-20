import SwiftUI

/// Absumo's palette — the Italian tricolore, reimagined as a neon "2040" scheme.
enum Palette {
    static let verde     = Color(hex: 0x21E3A1)   // electric emerald
    static let verdeDeep = Color(hex: 0x00A86B)
    static let rosso     = Color(hex: 0xFF4D6D)   // vivid coral-red
    static let rossoDeep = Color(hex: 0xE5142B)
    static let bianco    = Color(hex: 0xF6F7FB)   // luminous white

    static let ink       = Color(hex: 0x0A0E1A)   // deep space background
    static let ink2      = Color(hex: 0x121A2E)

    static let tricolore = [verde, bianco, rosso]

    /// Maps a unit's `accent` string to a colour.
    static func accent(_ name: String) -> Color {
        switch name {
        case "rosso":  return rosso
        case "bianco": return bianco
        default:       return verde
        }
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
