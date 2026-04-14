import Foundation

struct GeoCity: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let timezone: String // IANA format — NEVER convert to UTC

    // MARK: - Manual Init (for local construction)

    init(
        id: UUID = UUID(),
        name: String,
        country: String,
        latitude: Double,
        longitude: Double,
        timezone: String
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.timezone = timezone
    }

    // MARK: - Decodable (API responses don't include UUID)

    private enum CodingKeys: String, CodingKey {
        case name, country, latitude, longitude, timezone
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.country = try container.decode(String.self, forKey: .country)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.timezone = try container.decode(String.self, forKey: .timezone)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(country, forKey: .country)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(timezone, forKey: .timezone)
    }
}
