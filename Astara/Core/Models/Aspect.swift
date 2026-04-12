import Foundation
import SwiftUI

enum AspectType: String, Codable, CaseIterable {
    case conjunction
    case sextile
    case square
    case trine
    case opposition

    var angle: Double {
        switch self {
        case .conjunction: 0
        case .sextile: 60
        case .square: 90
        case .trine: 120
        case .opposition: 180
        }
    }

    var symbol: String {
        switch self {
        case .conjunction: "☌"
        case .sextile: "⚹"
        case .square: "□"
        case .trine: "△"
        case .opposition: "☍"
        }
    }

    var color: Color {
        switch self {
        case .conjunction: AstaraColors.gold
        case .sextile: AstaraColors.sage400
        case .square: AstaraColors.fire
        case .trine: AstaraColors.air
        case .opposition: AstaraColors.ember400
        }
    }

    var isHarmonious: Bool {
        switch self {
        case .conjunction, .sextile, .trine: true
        case .square, .opposition: false
        }
    }

    var defaultOrb: Double {
        switch self {
        case .conjunction: 8
        case .sextile: 6
        case .square: 7
        case .trine: 8
        case .opposition: 8
        }
    }
}

struct Aspect: Codable, Equatable, Identifiable {
    let id: UUID
    let planet1: PlanetKey
    let planet2: PlanetKey
    let type: AspectType
    let orb: Double
    let isApplying: Bool

    init(planet1: PlanetKey, planet2: PlanetKey, type: AspectType, orb: Double, isApplying: Bool = false) {
        self.id = UUID()
        self.planet1 = planet1
        self.planet2 = planet2
        self.type = type
        self.orb = orb
        self.isApplying = isApplying
    }
}
