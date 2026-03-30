import SwiftUI
import VPNMierukunStores

@MainActor
package struct VPNStatusMenuBarContainer: View {
    @ObservedObject var store: VPNMonitoringStore

    package init(store: VPNMonitoringStore) {
        self.store = store
    }

    package var body: some View {
        VPNStatusMenuBarPresenter(
            snapshot: store.snapshot,
            selectedServiceName: store.snapshot.serviceName ?? store.selectedServiceDisplayName,
            overlayEnabled: Binding(
                get: { store.settings.overlayEnabled },
                set: { store.updateOverlayEnabled($0) }
            ),
            startMonitoringOnLaunch: Binding(
                get: { store.settings.startMonitoringOnLaunch },
                set: { store.updateStartMonitoringOnLaunch($0) }
            ),
            isMonitoring: store.isMonitoring,
            errorMessage: store.lastErrorMessage,
            onToggleMonitoring: toggleMonitoring,
            onRefresh: store.refreshNow
        )
    }

    private func toggleMonitoring() {
        if store.isMonitoring {
            store.stopMonitoring()
        } else {
            store.startMonitoring()
        }
    }
}
