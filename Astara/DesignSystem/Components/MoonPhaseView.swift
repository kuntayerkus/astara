import SwiftUI

enum MoonPhaseType: Int, CaseIterable, Sendable {
    case newMoon = 0
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case fullMoon
    case waningGibbous
    case lastQuarter
    case waningCrescent
    
    var name: String {
        switch self {
        case .newMoon: return String(localized: "new_moon", defaultValue: "Yeni Ay")
        case .waxingCrescent: return String(localized: "waxing_crescent", defaultValue: "Hilal Büyüyen")
        case .firstQuarter: return String(localized: "first_quarter", defaultValue: "İlk Dördün")
        case .waxingGibbous: return String(localized: "waxing_gibbous", defaultValue: "Şişkin Ay")
        case .fullMoon: return String(localized: "full_moon", defaultValue: "Dolunay")
        case .waningGibbous: return String(localized: "waning_gibbous", defaultValue: "Küçülen Ay")
        case .lastQuarter: return String(localized: "last_quarter", defaultValue: "Son Dördün")
        case .waningCrescent: return String(localized: "waning_crescent", defaultValue: "Balzamik Ay")
        }
    }
    
    static func current() -> MoonPhaseType {
        let lp = 2551443.0 // Lunar cycle in seconds
        let now = Date().timeIntervalSince1970
        let knownNewMoon = 1618196400.0 // April 12, 2021
        let phase = ((now - knownNewMoon) / lp).truncatingRemainder(dividingBy: 1.0)
        
        let index = Int((phase * 8).rounded()) % 8
        return MoonPhaseType(rawValue: index) ?? .fullMoon
    }
}

struct MoonPhaseView: View {
    var phase: MoonPhaseType = MoonPhaseType.current()
    var size: CGFloat = 80
    var showName: Bool = true
    
    @State private var glowOpacity: Double = 0.5
    
    var body: some View {
        VStack(spacing: AstaraSpacing.md) {
            ZStack {
                // Base Moon Glow (Auras vary per phase)
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
                    .blur(radius: phase == .newMoon ? 2 : size / 3)
                    .opacity(phase == .newMoon ? 0.05 : glowOpacity)
                
                // Actual Moon Sphere
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.white, Color(hex: "#DCDCDC")]),
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size, height: size)
                
                // Shadow / Phase Cover
                GeometryReader { geo in
                    Path { path in
                        let w = geo.size.width
                        let h = geo.size.height
                        
                        path.addRect(CGRect(x: 0, y: 0, width: w, height: h))
                        
                    }
                    .fill(Color.black.opacity(0.85)) // Deep space shadow
                    .mask(phaseMask(width: geo.size.width))
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            }
            .onAppear {
                if phase == .fullMoon || phase == .waxingGibbous || phase == .waningGibbous {
                    withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                        glowOpacity = 0.9
                    }
                }
            }
            
            if showName {
                Text(phase.name)
                    .font(AstaraTypography.labelLarge)
                    .foregroundStyle(AstaraColors.textSecondary)
            }
        }
    }
    
    private func phaseMask(width: CGFloat) -> AnyView {
        let hw = width / 2
        
        switch phase {
        case .newMoon:
            return AnyView(Circle().frame(width: width, height: width))
        case .waxingCrescent:
            return AnyView(
                HStack(spacing: 0) {
                    Rectangle().frame(width: hw)
                    Ellipse().frame(width: hw * 1.5, height: width) // cover right side heavily
                        .offset(x: -hw * 0.75)
                }
            )
        case .firstQuarter:
            return AnyView(
                HStack(spacing: 0) {
                    Rectangle().frame(width: hw)
                    Color.clear.frame(width: hw)
                }
            )
        case .waxingGibbous:
            return AnyView(
                HStack(spacing: 0) {
                    Ellipse().frame(width: hw, height: width)
                        .offset(x: hw / 2)
                    Color.clear.frame(width: hw)
                }
                .frame(width: width, alignment: .leading)
            )
        case .fullMoon:
            return AnyView(Color.clear)
        case .waningGibbous:
            return AnyView(
                HStack(spacing: 0) {
                    Color.clear.frame(width: hw)
                    Ellipse().frame(width: hw, height: width)
                        .offset(x: -hw / 2)
                }
                .frame(width: width, alignment: .trailing)
            )
        case .lastQuarter:
            return AnyView(
                HStack(spacing: 0) {
                    Color.clear.frame(width: hw)
                    Rectangle().frame(width: hw)
                }
            )
        case .waningCrescent:
            return AnyView(
                HStack(spacing: 0) {
                    Color.clear.frame(width: hw) // let left be clear
                    Ellipse().frame(width: hw * 1.5, height: width) // cover left side heavily
                        .offset(x: hw * 0.75)
                }
            )
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 40) {
                ForEach(MoonPhaseType.allCases, id: \.self) { phase in
                    MoonPhaseView(phase: phase, size: 60)
                }
            }
            .padding(40)
        }
    }
}
