import SwiftUI
import VPNMierukunMenuBarFeature
import VPNMierukunSettingsFeature
import VPNMierukunStores

@MainActor
public struct VPNMierukunScenes: Scene {
    @ObservedObject private var store: VPNMonitoringStore

    public init() {
        _store = ObservedObject(wrappedValue: .shared)
    }

    public var body: some Scene {
        MenuBarExtra("VPN-Mierukun", systemImage: store.snapshot.state.symbolName) {
            VPNStatusMenuBarContainer(store: store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            VPNSettingsContainer(store: store)
                .frame(width: 420, height: 420)
                .padding(20)
        }
    }
}
