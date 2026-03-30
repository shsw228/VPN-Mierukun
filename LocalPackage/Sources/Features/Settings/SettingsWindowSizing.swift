import SwiftUI

enum SettingsTab: Hashable {
    case general
    case overlay
    case about

    var preferredContentSize: CGSize {
        switch self {
        case .general:
            CGSize(width: 420, height: 312)
        case .overlay:
            CGSize(width: 420, height: 388)
        case .about:
            CGSize(width: 420, height: 320)
        }
    }
}

@MainActor
final class SettingsWindowSizeController: ObservableObject {
    @Published private(set) var preferredContentSize = SettingsTab.general.preferredContentSize

    func updateSelectedTab(_ tab: SettingsTab) {
        let nextSize = tab.preferredContentSize
        guard preferredContentSize != nextSize else {
            return
        }
        preferredContentSize = nextSize
    }
}
