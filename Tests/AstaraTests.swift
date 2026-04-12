import XCTest

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
}
