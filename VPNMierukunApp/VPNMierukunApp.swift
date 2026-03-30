import SwiftUI
import VPNMierukunFeature

@main
struct VPNMierukunApp: App {
    @NSApplicationDelegateAdaptor(VPNMierukunAppDelegate.self) private var appDelegate

    var body: some Scene {
        VPNMierukunScenes()
    }
}
