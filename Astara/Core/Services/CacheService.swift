import Foundation
import ComposableArchitecture

// MARK: - Cache Policy

enum CachePolicy: String, Codable {
    case dailyHoroscope
    case planetPositions
    case dailyEnergy
    case retroCalendar
    case birthChart
    case geoSearch
    case timezone
    case blogArticles
    case aiResponse           // Ask Astara, time travel, ritual prompts
    case chartInterpretation  // AI chart readings (never expires per-user)
    case synastry             // Synastry comparison between user and a partner

    var ttl: TimeInterval {
        switch self {
        case .dailyHoroscope: AppConstants.CacheTTL.dailyHoroscope
        case .planetPositions: AppConstants.CacheTTL.planetPositions
        case .dailyEnergy: AppConstants.CacheTTL.dailyEnergy
        case .retroCalendar: AppConstants.CacheTTL.retroCalendar
        case .birthChart: AppConstants.CacheTTL.birthChart
        case .geoSearch: AppConstants.CacheTTL.geoSearch
        case .timezone: AppConstants.CacheTTL.timezone
        case .blogArticles: AppConstants.CacheTTL.blogArticles
        case .aiResponse: AppConstants.CacheTTL.aiResponse
        case .chartInterpretation: AppConstants.CacheTTL.chartInterpretation
        case .synastry: AppConstants.CacheTTL.synastry
        }
    }
}

// MARK: - Cache Entry

private struct CacheEntry: Codable {
    let data: Data
    let timestamp: Date
    let policy: CachePolicy
}

// MARK: - Cache Service

@DependencyClient
struct CacheService {
    var get: @Sendable (_ key: String, _ policy: CachePolicy) async -> Data?
    var set: @Sendable (_ key: String, _ data: Data, _ policy: CachePolicy) async -> Void
    var invalidate: @Sendable (_ key: String) async -> Void
    var clearAll: @Sendable () async -> Void
}

extension CacheService: DependencyKey {
    static let liveValue: CacheService = {
        let cacheDirectory: URL = {
            // Prefer the App Group container so the widget extension can read
            // cached daily horoscope / energy snapshots without hitting the
            // network. Fall back to the app sandbox if the App Group isn't
            // provisioned yet (e.g. local dev builds without the entitlement).
            if let appGroupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppConstants.appGroup
            ) {
                let cacheDir = appGroupURL.appendingPathComponent("AstaraCache", isDirectory: true)
                try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
                return cacheDir
            }
            let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            let cacheDir = paths[0].appendingPathComponent("AstaraCache", isDirectory: true)
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            return cacheDir
        }()

        @Sendable func fileURL(for key: String) -> URL {
            let safeKey = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
            return cacheDirectory.appendingPathComponent(safeKey)
        }

        return CacheService(
            get: { key, policy in
                let url = fileURL(for: key)
                guard let entryData = try? Data(contentsOf: url),
                      let entry = try? JSONDecoder().decode(CacheEntry.self, from: entryData) else {
                    return nil
                }

                // Check TTL (infinite for birthChart)
                if policy.ttl.isFinite {
                    let age = Date().timeIntervalSince(entry.timestamp)
                    if age > policy.ttl {
                        return nil // Expired
                    }
                }

                return entry.data
            },
            set: { key, data, policy in
                let entry = CacheEntry(data: data, timestamp: Date(), policy: policy)
                guard let entryData = try? JSONEncoder().encode(entry) else { return }
                let url = fileURL(for: key)
                try? entryData.write(to: url)
            },
            invalidate: { key in
                let url = fileURL(for: key)
                try? FileManager.default.removeItem(at: url)
            },
            clearAll: {
                try? FileManager.default.removeItem(at: cacheDirectory)
                try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            }
        )
    }()

    static let previewValue = CacheService(
        get: { _, _ in nil },
        set: { _, _, _ in },
        invalidate: { _ in },
        clearAll: { }
    )
}

extension DependencyValues {
    var cacheService: CacheService {
        get { self[CacheService.self] }
        set { self[CacheService.self] = newValue }
    }
}
