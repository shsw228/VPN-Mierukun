import Foundation
import VPNMierukunSharedModels

package protocol AppSettingsPersisting {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

package struct UserDefaultsAppSettingsPersistence: AppSettingsPersisting {
    private let defaults: UserDefaults
    private let key = "VPNMierukun.AppSettings"

    package init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    package func load() -> AppSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    package func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        defaults.set(data, forKey: key)
    }
}
