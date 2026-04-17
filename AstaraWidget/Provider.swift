import WidgetKit
import SwiftUI

// MARK: - Widget Entry

/// One row in the widget timeline. Wraps ``WidgetSnapshot`` with a `date` so
/// WidgetKit can order entries, plus a placeholder flag for redacted previews.
struct AstaraEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let isPlaceholder: Bool

    static let placeholderSnapshot = WidgetSnapshot(
        sunSignRawValue: ZodiacSign.leo.rawValue,
        energy: 72,
        theme: "denge",
        luckyColorHex: "#C9A96E",
        tip: "Bir bardak su iç, üç derin nefes al.",
        retroBanner: nil,
        isPremium: false,
        localePrefix: "tr",
        updatedAt: .now
    )
}

// MARK: - Timeline Provider

/// Reads the last ``WidgetSnapshot`` the host app wrote to the App Group
/// container. Never touches the network — if no snapshot exists (very first
/// install, before the app ran once) we fall back to a neutral placeholder.
///
/// Refresh policy mirrors the 6-hour daily cache TTL in
/// ``AppConstants/CacheTTL/dailyEnergy``. WidgetKit is free to ignore the hint,
/// but the host app also calls `WidgetCenter.reloadAllTimelines()` whenever it
/// writes a fresh snapshot so users see updates immediately on app foreground.
struct AstaraTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AstaraEntry {
        AstaraEntry(
            date: .now,
            snapshot: AstaraEntry.placeholderSnapshot,
            isPlaceholder: true
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (AstaraEntry) -> Void
    ) {
        let snapshot = WidgetSnapshotStore.read() ?? AstaraEntry.placeholderSnapshot
        let entry = AstaraEntry(
            date: .now,
            snapshot: snapshot,
            isPlaceholder: context.isPreview && WidgetSnapshotStore.read() == nil
        )
        completion(entry)
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<AstaraEntry>) -> Void
    ) {
        let snapshot = WidgetSnapshotStore.read() ?? AstaraEntry.placeholderSnapshot
        let now = Date()
        let entry = AstaraEntry(date: now, snapshot: snapshot, isPlaceholder: false)
        // 6 hours matches the daily-energy cache TTL in the host app.
        let refresh = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now.addingTimeInterval(21_600)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}
