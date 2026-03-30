import AppKit
import Foundation

public enum VPNDisplayState: String, Codable, CaseIterable, Sendable {
    case connected
    case disconnected
    case transitioning
    case unknown

    package var title: String {
        switch self {
        case .connected:
            "接続中"
        case .disconnected:
            "未接続"
        case .transitioning:
            "切り替え中"
        case .unknown:
            "不明"
        }
    }

    package var symbolName: String {
        switch self {
        case .connected:
            "checkmark.circle.fill"
        case .disconnected:
            "xmark.circle.fill"
        case .transitioning:
            "arrow.triangle.2.circlepath.circle.fill"
        case .unknown:
            "questionmark.circle.fill"
        }
    }
}

public struct VPNStatusSnapshot: Equatable, Sendable {
    public var state: VPNDisplayState
    public var serviceName: String?
    public var rawStatus: String
    public var updatedAt: Date

    package init(
        state: VPNDisplayState,
        serviceName: String?,
        rawStatus: String,
        updatedAt: Date
    ) {
        self.state = state
        self.serviceName = serviceName
        self.rawStatus = rawStatus
        self.updatedAt = updatedAt
    }

    package static let initial = VPNStatusSnapshot(
        state: .unknown,
        serviceName: nil,
        rawStatus: "未取得",
        updatedAt: .now
    )
}

public struct AppSettings: Codable, Sendable {
    public var selectedServiceName: String?
    public var overlayEnabled: Bool
    public var overlayThickness: Double
    public var connectedColorHex: String
    public var disconnectedColorHex: String
    public var transitioningColorHex: String
    public var unknownColorHex: String
    public var startMonitoringOnLaunch: Bool

    public init(
        selectedServiceName: String? = nil,
        overlayEnabled: Bool = true,
        overlayThickness: Double = 6,
        connectedColorHex: String = "#22C55E",
        disconnectedColorHex: String = "#EF4444",
        transitioningColorHex: String = "#F59E0B",
        unknownColorHex: String = "#6B7280",
        startMonitoringOnLaunch: Bool = true
    ) {
        self.selectedServiceName = selectedServiceName
        self.overlayEnabled = overlayEnabled
        self.overlayThickness = overlayThickness
        self.connectedColorHex = connectedColorHex
        self.disconnectedColorHex = disconnectedColorHex
        self.transitioningColorHex = transitioningColorHex
        self.unknownColorHex = unknownColorHex
        self.startMonitoringOnLaunch = startMonitoringOnLaunch
    }

    package func colorHex(for state: VPNDisplayState) -> String {
        switch state {
        case .connected:
            connectedColorHex
        case .disconnected:
            disconnectedColorHex
        case .transitioning:
            transitioningColorHex
        case .unknown:
            unknownColorHex
        }
    }

    package mutating func setColorHex(_ hex: String, for state: VPNDisplayState) {
        switch state {
        case .connected:
            connectedColorHex = hex
        case .disconnected:
            disconnectedColorHex = hex
        case .transitioning:
            transitioningColorHex = hex
        case .unknown:
            unknownColorHex = hex
        }
    }

    package func color(for state: VPNDisplayState) -> NSColor {
        NSColor(hex: colorHex(for: state)) ?? .systemGray
    }
}

package extension NSColor {
    convenience init?(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard sanitized.count == 6, let value = Int(sanitized, radix: 16) else {
            return nil
        }

        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 0.9)
    }
}
