import Foundation

struct FriendDynamic: Codable, Equatable, Identifiable {
    let id: UUID
    let friendName: String
    let friendSign: ZodiacSign
    let compatibility: Compatibility
    let insight: String
    let suggestedAction: String

    init(
        id: UUID = UUID(),
        friendName: String,
        friendSign: ZodiacSign,
        compatibility: Compatibility,
        insight: String,
        suggestedAction: String
    ) {
        self.id = id
        self.friendName = friendName
        self.friendSign = friendSign
        self.compatibility = compatibility
        self.insight = insight
        self.suggestedAction = suggestedAction
    }
}

