import SwiftUI

enum AstaraColors {
    // MARK: - Background Gradient
    static let backgroundStart = Color(hex: "#0d0a14")
    static let backgroundEnd = Color(hex: "#1c1520")

    // MARK: - Astara Gold (Primary Accent)
    static let gold = Color(hex: "#C9A96E")
    static let goldLight = Color(hex: "#E8D5A3")
    static let goldDark = Color(hex: "#8B7340")

    // MARK: - Ember Palette (Fire/Passion)
    static let ember50 = Color(hex: "#FFF7ED")
    static let ember400 = Color(hex: "#FB923C")
    static let ember600 = Color(hex: "#EA580C")

    // MARK: - Sage Palette (Earth/Calm)
    static let sage400 = Color(hex: "#4ADE80")
    static let sage600 = Color(hex: "#16A34A")

    // MARK: - Mist Palette (Air/Thought)
    static let mist400 = Color(hex: "#94A3B8")
    static let mist600 = Color(hex: "#475569")

    // MARK: - Element Colors
    static let fire = Color(hex: "#EF4444")
    static let earth = Color(hex: "#A3E635")
    static let air = Color(hex: "#38BDF8")
    static let water = Color(hex: "#818CF8")

    // MARK: - Semantic
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.4)
    static let cardBackground = Color.white.opacity(0.05)
    static let cardBorder = Color.white.opacity(0.08)

    // MARK: - Deep Backgrounds (richer, darker foundation)
    static let backgroundDeep = Color(hex: "#080610")   // Deepest base layer
    static let backgroundMid  = Color(hex: "#110D1C")   // Mid atmosphere layer
    static let backgroundWarm = Color(hex: "#1A1028")   // Daily tab warm variant

    // MARK: - Premium Accents
    static let amethyst      = Color(hex: "#4A2D8A")    // Section header / nebula glow
    static let starlight     = Color(hex: "#C8D4E8")    // Silver-white secondary accent
    static let moonCream     = Color(hex: "#F0EAD6")    // Pull-quote warmth
    static let celestialTeal = Color(hex: "#1B6B8A")    // Transit & alert accent
    static let goldGlow      = Color(hex: "#C9A96E")    // Same as gold — use .opacity(0.25) for radial glow

    // MARK: - Chronicle Card
    static let chronicleBorder = Color(hex: "#C9A96E").opacity(0.45)
    static let chronicleGradientTop = Color(hex: "#1E1435")
    static let chronicleGradientBottom = Color(hex: "#080610")
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: Double
        switch hex.count {
        case 6:
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255,
                1
            )
        case 8:
            (r, g, b, a) = (
                Double((int >> 24) & 0xFF) / 255,
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255
            )
        default:
            (r, g, b, a) = (0, 0, 0, 1)
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
