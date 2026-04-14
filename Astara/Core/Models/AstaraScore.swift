import Foundation

struct AstaraScore: Codable, Equatable {
    let love: Int
    let work: Int
    let energy: Int
    let focus: Int

    static let zero = AstaraScore(love: 0, work: 0, energy: 0, focus: 0)
}

