import Foundation

// MARK: - Widget Snapshot

/// Compact, self-contained snapshot the host app writes to the shared App
/// Group container so the widget extension can render without touching
/// SwiftData, the network, or any TCA dependency graph.
///
/// The widget target includes **this file only** — no ``CacheService`` or
/// ``PersistenceClient`` dependencies — keeping its module small and safe.
struct WidgetSnapshot: Codable, Equatable, Sendable {
    /// User's sun sign raw value (e.g. "scorpio"). Used for greeting + symbol.
    let sunSignRawValue: String
    /// 0-100 daily energy bar.
    let energy: Int
    /// Today's theme (short phrase, e.g. "denge").
    let theme: String
    /// Lucky color hex for the small widget dot.
    let luckyColorHex: String?
    /// Optional ritual tip for medium/large widgets.
    let tip: String?
    /// Active retrograde banner text (nil if nothing in retro today).
    let retroBanner: String?
    /// Whether the user has an active premium subscription. Drives medium/large
    /// widget gating on the widget side (no network call).
    let isPremium: Bool
    /// Locale prefix ("tr", "en") for the widget to localize labels.
    let localePrefix: String
    /// When this snapshot was generated, for the "son güncelleme" hint.
    let updatedAt: Date
}

// MARK: - Snapshot Store

/// Tiny JSON-file-on-disk store for ``WidgetSnapshot``. Both the host app and
/// the widget use this — the app writes, the widget reads. Intentionally does
/// **not** depend on any TCA machinery so the widget can link it standalone.
enum WidgetSnapshotStore {
    /// File name inside the App Group container.
    private static let fileName = "widget_snapshot.json"

    static var fileURL: URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroup
        ) else { return nil }
        return container.appendingPathComponent(fileName)
    }

    /// Read the last snapshot written by the host app. `nil` if the file is
    /// missing (first launch before the main app ever refreshed Home).
    static func read() -> WidgetSnapshot? {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder.widgetStore.decode(WidgetSnapshot.self, from: data)
    }

    /// Atomically write a snapshot. Caller should invoke
    /// `WidgetCenter.shared.reloadAllTimelines()` afterwards (host app only).
    @discardableResult
    static func write(_ snapshot: WidgetSnapshot) -> Bool {
        guard let url = fileURL,
              let data = try? JSONEncoder.widgetStore.encode(snapshot) else {
            return false
        }
        do {
            try data.write(to: url, options: [.atomic])
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Coders

private extension JSONDecoder {
    static let widgetStore: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

private extension JSONEncoder {
    static let widgetStore: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
