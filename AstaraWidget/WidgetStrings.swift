import Foundation
import SwiftUI

// MARK: - Widget Localization
//
// Widget target does not pull in the main app's String Catalog (to keep the
// binary small), so we ship a tiny hand-rolled table keyed by ``localePrefix``.
// Only two languages for v1 — Turkish (primary) and English (global v2).

enum WidgetStrings {
    static func greeting(for sign: ZodiacSign, locale: String) -> String {
        switch locale {
        case "tr": "\(sign.turkishName)"
        default: sign.rawValue.capitalized
        }
    }

    static func todayLabel(locale: String) -> String {
        locale == "tr" ? "Bugün" : "Today"
    }

    static func energyLabel(locale: String) -> String {
        locale == "tr" ? "Enerji" : "Energy"
    }

    static func themeLabel(locale: String) -> String {
        locale == "tr" ? "Tema" : "Theme"
    }

    static func ritualLabel(locale: String) -> String {
        locale == "tr" ? "Ritüel" : "Ritual"
    }

    static func retroLabel(locale: String) -> String {
        locale == "tr" ? "Retro" : "Retrograde"
    }

    static func premiumGateTitle(locale: String) -> String {
        locale == "tr" ? "Astara Premium" : "Astara Premium"
    }

    static func premiumGateBody(locale: String) -> String {
        locale == "tr"
            ? "Ritüel, retro ve transit ipuçlarını açmak için Premium."
            : "Unlock ritual, retro and transit hints with Premium."
    }

    static func updatedAt(_ date: Date, locale: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: locale == "tr" ? "tr_TR" : "en_US")
        formatter.dateFormat = "HH:mm"
        let prefix = locale == "tr" ? "Son güncelleme" : "Updated"
        return "\(prefix) \(formatter.string(from: date))"
    }
}
