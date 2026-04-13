import SwiftUI

enum AstaraTypography {
    // Font.custom with relativeTo provides system font fallback when custom font is missing
    // MARK: - Display & Titles (Cormorant Garamond — serif, elegant)
    static let displayLarge = Font.custom("CormorantGaramond-Bold", size: 34, relativeTo: .largeTitle)
    static let displayMedium = Font.custom("CormorantGaramond-SemiBold", size: 28, relativeTo: .title)
    static let titleLarge = Font.custom("CormorantGaramond-Medium", size: 22, relativeTo: .title2)
    static let titleMedium = Font.custom("CormorantGaramond-Medium", size: 18, relativeTo: .title3)

    // MARK: - Body & Labels (Plus Jakarta Sans — modern, readable)
    static let bodyLarge = Font.custom("PlusJakartaSans-Regular", size: 17, relativeTo: .body)
    static let bodyMedium = Font.custom("PlusJakartaSans-Regular", size: 15, relativeTo: .callout)
    static let bodySmall = Font.custom("PlusJakartaSans-Regular", size: 13, relativeTo: .footnote)
    static let labelLarge = Font.custom("PlusJakartaSans-SemiBold", size: 15, relativeTo: .callout)
    static let labelMedium = Font.custom("PlusJakartaSans-SemiBold", size: 13, relativeTo: .footnote)
    static let caption = Font.custom("PlusJakartaSans-Regular", size: 11, relativeTo: .caption)
}
