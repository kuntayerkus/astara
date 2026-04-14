import XCTest
@testable import Astara

final class AstaraTests: XCTestCase {
    func testZodiacSignCount() {
        // Ensure all 12 zodiac signs are defined
        XCTAssertEqual(ZodiacSign.allCases.count, 12)
    }

    func testPlanetKeyNoTurkishCharacters() {
        // CRITICAL: Planet keys must never contain Turkish characters (ü, ö, ş, etc.)
        for planet in PlanetKey.allCases {
            let rawValue = planet.rawValue
            XCTAssertFalse(rawValue.contains("ü"), "\(rawValue) contains Turkish 'ü'")
            XCTAssertFalse(rawValue.contains("ö"), "\(rawValue) contains Turkish 'ö'")
            XCTAssertFalse(rawValue.contains("ş"), "\(rawValue) contains Turkish 'ş'")
            XCTAssertFalse(rawValue.contains("ç"), "\(rawValue) contains Turkish 'ç'")
            XCTAssertFalse(rawValue.contains("ğ"), "\(rawValue) contains Turkish 'ğ'")
            XCTAssertFalse(rawValue.contains("ı"), "\(rawValue) contains Turkish 'ı'")
        }
    }

    func testElementDistribution() {
        // Each element should have exactly 3 zodiac signs
        let elements: [Element] = [.fire, .earth, .air, .water]
        for element in elements {
            let signs = ZodiacSign.allCases.filter { $0.element == element }
            XCTAssertEqual(signs.count, 3, "\(element) should have exactly 3 signs")
        }
    }

    func testIANATimezoneValidation() {
        XCTAssertTrue(IANATimezone.isValid("Europe/Istanbul"))
        XCTAssertTrue(IANATimezone.isValid("America/New_York"))
        XCTAssertFalse(IANATimezone.isValid("Invalid/Timezone"))
    }

    func testBirthChartPreview() {
        let chart = BirthChart.preview
        XCTAssertNotNil(chart.sunSign)
        XCTAssertNotNil(chart.moonSign)
        XCTAssertNotNil(chart.risingSign)
        XCTAssertFalse(chart.planets.isEmpty)
        XCTAssertFalse(chart.houses.isEmpty)
    }

    func testDeepLinkChartRoutesToChartTab() {
        let url = URL(string: "astara://chart")!
        let tab = AppFeature.mapDeepLinkToTab(url)
        XCTAssertEqual(tab, .chart)
    }

    func testDeepLinkDailyRoutesToDailyTab() {
        let url = URL(string: "astara://daily")!
        let tab = AppFeature.mapDeepLinkToTab(url)
        XCTAssertEqual(tab, .daily)
    }

    func testDeepLinkCompatibilityRoutesToCompatibilityTab() {
        let url = URL(string: "astara://compatibility")!
        let tab = AppFeature.mapDeepLinkToTab(url)
        XCTAssertEqual(tab, .compatibility)
    }

    func testDeepLinkUnknownReturnsNil() {
        let url = URL(string: "astara://unknown")!
        let tab = AppFeature.mapDeepLinkToTab(url)
        XCTAssertNil(tab)
    }

    func testLocalFallbackChartProducesCorePoints() throws {
        let chart = try AstrologyEngineClient.liveValue.fallbackChart(
            "1995-03-15",
            "14:30",
            41.01,
            28.98,
            "Europe/Istanbul"
        )

        XCTAssertFalse(chart.planets.isEmpty)
        XCTAssertEqual(chart.houses.count, 12)
        XCTAssertNotNil(chart.sunSign)
        XCTAssertNotNil(chart.moonSign)
        XCTAssertNotNil(chart.risingSign)

        if let asc = chart.ascendant {
            XCTAssertTrue((0...360).contains(asc.degree))
        } else {
            XCTFail("Ascendant must exist in fallback chart")
        }
    }
}
