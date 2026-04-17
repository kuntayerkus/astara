import WidgetKit
import SwiftUI

// MARK: - Widget Bundle
//
// Entry point for the AstaraWidget extension. Three tiers:
//   - DailyEnergyWidget (small, free) — sun sign + energy bar + theme + lucky color
//   - DailyDetailWidget (medium, premium) — adds ritual tip + retrograde banner
//   - CosmicOverviewWidget (large, premium) — full daily context card
//
// All widgets read from the shared ``WidgetSnapshotStore`` written by the host
// app — no network / SwiftData / TCA dependency is linked into this target.

@main
struct AstaraWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyEnergyWidget()
        DailyDetailWidget()
        CosmicOverviewWidget()
    }
}
