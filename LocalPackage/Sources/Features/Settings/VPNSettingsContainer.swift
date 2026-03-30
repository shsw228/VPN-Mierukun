import SwiftUI
import VPNMierukunSharedModels
import VPNMierukunStores

@MainActor
package struct VPNSettingsContainer: View {
    @ObservedObject var store: VPNMonitoringStore
    @StateObject private var windowSizeController = SettingsWindowSizeController()
    @State private var selectedTab: SettingsTab = .general

    package init(store: VPNMonitoringStore) {
        self.store = store
    }

    package var body: some View {
        VPNSettingsPresenter(
            availableServices: store.availableServices,
            selectedTab: $selectedTab,
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
            connectedAlpha: alphaBinding(for: .connected),
            disconnectedColorHex: colorBinding(for: .disconnected),
            disconnectedAlpha: alphaBinding(for: .disconnected),
            transitioningColorHex: colorBinding(for: .transitioning),
            transitioningAlpha: alphaBinding(for: .transitioning),
            unknownColorHex: colorBinding(for: .unknown),
            unknownAlpha: alphaBinding(for: .unknown),
            onBeginColorPreview: store.beginColorPreview(for:),
            onEndColorPreview: store.endColorPreview,
            onUpdateColor: { state, color in
                store.updateColor(color, for: state)
            },
            onResetOverlayColors: store.resetOverlayColorsToDefaults,
            snapshot: store.snapshot
        )
        .onAppear {
            windowSizeController.updateSelectedTab(selectedTab)
        }
        .onChange(of: selectedTab) { _, newValue in
            windowSizeController.updateSelectedTab(newValue)
        }
        .background(
            SettingsWindowLifecycleObserver(
                preferredContentSize: windowSizeController.preferredContentSize,
                onShow: store.beginSettingsPreview,
                onHide: store.endSettingsPreview
            )
        )
    }

    private func colorBinding(for state: VPNDisplayState) -> Binding<String> {
        Binding(
            get: { store.colorHex(for: state) },
            set: { store.updateColorHex($0, for: state) }
        )
    }

    private func alphaBinding(for state: VPNDisplayState) -> Binding<Double> {
        Binding(
            get: { store.alpha(for: state) },
            set: { store.updateAlpha($0, for: state) }
        )
    }
}
