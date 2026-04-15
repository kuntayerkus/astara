import SwiftUI

// MARK: - Ambient Style

/// The atmospheric character of each tab's background.
enum AstaraAmbient {
    case home    // Indigo / amethyst nebula — cosmic depth
    case chart   // Near-black, minimal — concentration
    case daily   // Warm purple — reading comfort
    case neutral // Default — same as home
}

// MARK: - GradientBackground

struct GradientBackground: View {
    var ambient: AstaraAmbient = .home
    @State private var animate = false

    var body: some View {
        ZStack {
            // Layer 1 — deepest base
            baseLayer

            // Layer 2 — nebula radial glow (tab-specific)
            nebularGlow
                .opacity(0.55)

            // Layer 3 — film-grain noise
            NoiseTextureView(opacity: 0.032)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }

    // MARK: - Layer 1: Base gradient

    private var baseLayer: some View {
        LinearGradient(
            colors: baseColors,
            startPoint: animate ? .topLeading : .top,
            endPoint: animate ? .bottomTrailing : .bottom
        )
        .ignoresSafeArea()
    }

    private var baseColors: [Color] {
        switch ambient {
        case .home:    return [AstaraColors.backgroundDeep, AstaraColors.backgroundMid]
        case .chart:   return [Color(hex: "#050408"), AstaraColors.backgroundDeep]
        case .daily:   return [AstaraColors.backgroundWarm, AstaraColors.backgroundDeep]
        case .neutral: return [AstaraColors.backgroundStart, AstaraColors.backgroundEnd]
        }
    }

    // MARK: - Layer 2: Nebula radial glow

    private var nebularGlow: some View {
        GeometryReader { geo in
            ZStack {
                // Primary nebula blob — upper-center
                RadialGradient(
                    colors: [primaryGlowColor.opacity(0.22), Color.clear],
                    center: .init(x: 0.5, y: animate ? 0.15 : 0.2),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.65
                )

                // Secondary accent blob — lower-trailing (subtler)
                RadialGradient(
                    colors: [secondaryGlowColor.opacity(0.10), Color.clear],
                    center: .init(x: animate ? 0.85 : 0.75, y: 0.72),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.50
                )
            }
        }
        .ignoresSafeArea()
    }

    private var primaryGlowColor: Color {
        switch ambient {
        case .home, .neutral: return AstaraColors.amethyst
        case .chart:          return Color(hex: "#1A0E3A")
        case .daily:          return AstaraColors.backgroundWarm
        }
    }

    private var secondaryGlowColor: Color {
        switch ambient {
        case .home, .neutral: return AstaraColors.gold
        case .chart:          return AstaraColors.amethyst.opacity(0.5)
        case .daily:          return AstaraColors.goldDark
        }
    }
}

// MARK: - View extension

extension View {
    func astaraBackground(ambient: AstaraAmbient = .home) -> some View {
        self.background { GradientBackground(ambient: ambient) }
    }
}

#Preview {
    TabView {
        Color.clear
            .overlay(Text("Home").foregroundStyle(.white))
            .astaraBackground(ambient: .home)
            .tabItem { Label("Home", systemImage: "house") }

        Color.clear
            .overlay(Text("Chart").foregroundStyle(.white))
            .astaraBackground(ambient: .chart)
            .tabItem { Label("Chart", systemImage: "circle.hexagongrid") }

        Color.clear
            .overlay(Text("Daily").foregroundStyle(.white))
            .astaraBackground(ambient: .daily)
            .tabItem { Label("Daily", systemImage: "sun.max") }
    }
    .tint(AstaraColors.gold)
    .preferredColorScheme(.dark)
}
