import Foundation

enum AppLocale: String, CaseIterable {
    case turkish = "tr"
    case english = "en"
    case spanish = "es"
    case portuguese = "pt"

    var displayName: String {
        switch self {
        case .turkish: "Türkçe"
        case .english: "English"
        case .spanish: "Español"
        case .portuguese: "Português"
        }
    }

    static var current: AppLocale {
        let preferredLanguage = Locale.preferredLanguages.first ?? "tr"
        let languageCode = String(preferredLanguage.prefix(2))
        return AppLocale(rawValue: languageCode) ?? .turkish
    }
}
