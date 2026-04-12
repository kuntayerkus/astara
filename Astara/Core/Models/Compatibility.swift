import Foundation

struct Compatibility: Codable, Equatable, Identifiable {
    var id: String { "\(sign1.rawValue)-\(sign2.rawValue)" }

    let sign1: ZodiacSign
    let sign2: ZodiacSign
    let overallScore: Int // 0-100
    let loveScore: Int
    let friendshipScore: Int
    let workScore: Int
    let description: String
}

// MARK: - Preview Data

extension Compatibility {
    static let preview = Compatibility(
        sign1: .pisces,
        sign2: .scorpio,
        overallScore: 88,
        loveScore: 92,
        friendshipScore: 85,
        workScore: 78,
        description: "Su elementinin iki güçlü burcu. Derin duygusal bağ kurabilirsiniz."
    )
}
