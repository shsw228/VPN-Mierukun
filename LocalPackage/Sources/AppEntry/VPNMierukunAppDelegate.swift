import AppKit
import Foundation
import VPNMierukunStores

@MainActor
public final class VPNMierukunAppDelegate: NSObject, NSApplicationDelegate {
    private let store: VPNMonitoringStore
    private var screenObserver: NSObjectProtocol?

    public override init() {
        store = .shared
        super.init()
    }

    deinit {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registerScreenObserverIfNeeded()
        store.start()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        store.stop()
    }

    private func registerScreenObserverIfNeeded() {
        guard screenObserver == nil else {
            return
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.store.refreshOverlayForCurrentScreens()
            }
        }
    }
}
