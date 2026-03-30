import SwiftUI
import VPNMierukunSharedModels
import VPNMierukunStores

@MainActor
package struct VPNSettingsContainer: View {
    @ObservedObject var store: VPNMonitoringStore

    package init(store: VPNMonitoringStore) {
        self.store = store
    }

    package var body: some View {
        VPNSettingsPresenter(
            availableServices: store.availableServices,
            selectedServiceID: Binding(
                get: { store.settings.selectedServiceID ?? "" },
                set: { store.updateSelectedServiceID($0.isEmpty ? nil : $0) }
            ),
            startMonitoringOnLaunch: Binding(
                get: { store.settings.startMonitoringOnLaunch },
                set: { store.updateStartMonitoringOnLaunch($0) }
            ),
            overlayEnabled: Binding(
                get: { store.settings.overlayEnabled },
                set: { store.updateOverlayEnabled($0) }
            ),
            overlayThickness: Binding(
                get: { store.settings.overlayThickness },
                set: { store.updateOverlayThickness($0) }
            ),
            connectedColorHex: colorBinding(for: .connected),
            disconnectedColorHex: colorBinding(for: .disconnected),
            transitioningColorHex: colorBinding(for: .transitioning),
            unknownColorHex: colorBinding(for: .unknown),
            snapshot: store.snapshot
        )
    }

    private func colorBinding(for state: VPNDisplayState) -> Binding<String> {
        Binding(
            get: { store.colorHex(for: state) },
            set: { store.updateColorHex($0, for: state) }
        )
    }
}
