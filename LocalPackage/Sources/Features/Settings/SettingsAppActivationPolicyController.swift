import AppKit

@MainActor
final class SettingsAppActivationPolicyController {
    static let shared = SettingsAppActivationPolicyController()

    func update(isShowingSettings: Bool) {
        NSApp.setActivationPolicy(isShowingSettings ? .regular : .accessory)
        if isShowingSettings {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
