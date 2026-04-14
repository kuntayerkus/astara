import Foundation
import ComposableArchitecture

@DependencyClient
struct AskAstaraService {
    var ask: @Sendable (_ question: String, _ sign: ZodiacSign, _ horoscope: DailyHoroscope?) async -> String = { _, _, _ in "" }
}

extension AskAstaraService: DependencyKey {
    static let liveValue = AskAstaraService(
        ask: { question, sign, horoscope in
            let energy = horoscope?.energy ?? 50
            let theme = horoscope?.theme ?? "denge"
            let q = question.lowercased()

            if q.contains("ask") || q.contains("iliski") || q.contains("sev") {
                return "\(sign.turkishName) icin bugun iliskilerde tempo yuksek. \(theme) temasini korursan iletisim daha temiz akar."
            }
            if q.contains("is") || q.contains("kariyer") || q.contains("para") {
                return "Is tarafinda once netlik sonra hiz: enerji %\(energy). Kisa bir plan yapip tek kritik isi bitir."
            }
            if q.contains("ne yap") || q.contains("bugun") {
                return "Bugun \(sign.turkishName) icin en iyi hamle: daginik isleri toplamak ve bir konuda net karar vermek."
            }
            return "Soru guzel. \(sign.turkishName) enerjinde bugun ana tema \(theme). Fazla degil, dogru olana odaklan."
        }
    )

    static let previewValue = AskAstaraService(
        ask: { _, _, _ in "Preview cevap." }
    )
}

extension DependencyValues {
    var askAstaraService: AskAstaraService {
        get { self[AskAstaraService.self] }
        set { self[AskAstaraService.self] = newValue }
    }
}

