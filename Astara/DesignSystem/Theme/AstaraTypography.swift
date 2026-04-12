import SwiftUI

enum AstaraTypography {
    // MARK: - Display & Titles (Cormorant Garamond — serif, elegant)
    static let displayLarge = Font.custom("CormorantGaramond-Bold", size: 34)
    static let displayMedium = Font.custom("CormorantGaramond-SemiBold", size: 28)
    static let titleLarge = Font.custom("CormorantGaramond-Medium", size: 22)
    static let titleMedium = Font.custom("CormorantGaramond-Medium", size: 18)

    // MARK: - Body & Labels (Plus Jakarta Sans — modern, readable)
    static let bodyLarge = Font.custom("PlusJakartaSans-Regular", size: 17)
    static let bodyMedium = Font.custom("PlusJakartaSans-Regular", size: 15)
    static let bodySmall = Font.custom("PlusJakartaSans-Regular", size: 13)
    static let labelLarge = Font.custom("PlusJakartaSans-SemiBold", size: 15)
    static let labelMedium = Font.custom("PlusJakartaSans-SemiBold", size: 13)
    static let caption = Font.custom("PlusJakartaSans-Regular", size: 11)

    // MARK: - Fallback (system fonts if custom fonts aren't loaded)
    static let displayLargeFallback = Font.system(size: 34, weight: .bold, design: .serif)
    static let bodyLargeFallback = Font.system(size: 17, weight: .regular, design: .default)
}
