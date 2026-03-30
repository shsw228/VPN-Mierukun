import Foundation
import VPNMierukunSharedModels
import Yams

package protocol AppSettingsPersisting {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

package struct XDGConfigAppSettingsPersistence: AppSettingsPersisting {
    private let fileManager: FileManager
    private let environment: [String: String]

    package init(
        fileManager: FileManager = .default,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.fileManager = fileManager
        self.environment = environment
    }

    package func load() -> AppSettings {
        guard let fileURL = configFileURL(),
              let data = try? Data(contentsOf: fileURL),
              let settings = YamlAppSettingsCodec.decode(data) else {
            return AppSettings()
        }
        return settings
    }

    package func save(_ settings: AppSettings) {
        guard let directoryURL = configDirectoryURL() else {
            return
        }

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let data = YamlAppSettingsCodec.encode(settings)
            try data.write(to: directoryURL.appendingPathComponent("config.yaml"), options: .atomic)
        } catch {
            assertionFailure("Failed to save config.yaml: \(error)")
        }
    }

    private func configFileURL() -> URL? {
        configDirectoryURL()?.appendingPathComponent("config.yaml")
    }

    private func configDirectoryURL() -> URL? {
        if let xdgConfigHome = environment["XDG_CONFIG_HOME"],
           !xdgConfigHome.isEmpty {
            return URL(fileURLWithPath: xdgConfigHome, isDirectory: true)
                .appendingPathComponent("VPN-Mierukun", isDirectory: true)
        }

        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("VPN-Mierukun", isDirectory: true)
    }
}

private enum YamlAppSettingsCodec {
    static func decode(_ data: Data) -> AppSettings? {
        let decoder = YAMLDecoder()
        guard let document = try? decoder.decode(AppSettingsDocument.self, from: data) else {
            return nil
        }
        let defaults = AppSettings()

        return AppSettings(
            selectedServiceID: normalizeOptionalString(document.selectedServiceID),
            overlayEnabled: document.overlayEnabled ?? defaults.overlayEnabled,
            overlayThickness: normalizeOverlayThickness(document.overlayThickness) ?? defaults.overlayThickness,
            connectedColorHex: normalizeHex(document.connectedColorHex) ?? defaults.connectedColorHex,
            connectedAlpha: normalizeAlpha(document.connectedAlpha) ?? defaults.connectedAlpha,
            disconnectedColorHex: normalizeHex(document.disconnectedColorHex) ?? defaults.disconnectedColorHex,
            disconnectedAlpha: normalizeAlpha(document.disconnectedAlpha) ?? defaults.disconnectedAlpha,
            transitioningColorHex: normalizeHex(document.transitioningColorHex) ?? defaults.transitioningColorHex,
            transitioningAlpha: normalizeAlpha(document.transitioningAlpha) ?? defaults.transitioningAlpha,
            unknownColorHex: normalizeHex(document.unknownColorHex) ?? defaults.unknownColorHex,
            unknownAlpha: normalizeAlpha(document.unknownAlpha) ?? defaults.unknownAlpha,
            startMonitoringOnLaunch: document.startMonitoringOnLaunch ?? defaults.startMonitoringOnLaunch
        )
    }

    static func encode(_ settings: AppSettings) -> Data {
        let encoder = YAMLEncoder()
        let document = AppSettingsDocument(settings: settings)
        let yaml = (try? encoder.encode(document)) ?? ""
        return Data(yaml.utf8)
    }

    private struct AppSettingsDocument: Codable {
        var selectedServiceID: String?
        var overlayEnabled: Bool?
        var overlayThickness: Double?
        var connectedColorHex: String?
        var connectedAlpha: Double?
        var disconnectedColorHex: String?
        var disconnectedAlpha: Double?
        var transitioningColorHex: String?
        var transitioningAlpha: Double?
        var unknownColorHex: String?
        var unknownAlpha: Double?
        var startMonitoringOnLaunch: Bool?

        init(settings: AppSettings) {
            selectedServiceID = settings.selectedServiceID
            overlayEnabled = settings.overlayEnabled
            overlayThickness = settings.overlayThickness
            connectedColorHex = settings.connectedColorHex
            connectedAlpha = settings.connectedAlpha
            disconnectedColorHex = settings.disconnectedColorHex
            disconnectedAlpha = settings.disconnectedAlpha
            transitioningColorHex = settings.transitioningColorHex
            transitioningAlpha = settings.transitioningAlpha
            unknownColorHex = settings.unknownColorHex
            unknownAlpha = settings.unknownAlpha
            startMonitoringOnLaunch = settings.startMonitoringOnLaunch
        }
    }

    private static func normalizeOptionalString(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizeOverlayThickness(_ value: Double?) -> Double? {
        guard let value, value > 0 else {
            return nil
        }

        return value
    }

    private static func normalizeHex(_ value: String?) -> String? {
        let sanitized = (value ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()

        guard sanitized.count == 6,
              sanitized.allSatisfy({ $0.isHexDigit }) else {
            return nil
        }

        return "#\(sanitized)"
    }

    private static func normalizeAlpha(_ value: Double?) -> Double? {
        guard let alpha = value,
              (0...1).contains(alpha) else {
            return nil
        }

        return alpha
    }
}
