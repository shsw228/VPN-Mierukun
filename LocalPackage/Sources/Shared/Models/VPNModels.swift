import Foundation

public enum VPNDisplayState: String, Codable, CaseIterable, Identifiable, Sendable {
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

    public var id: String { rawValue }
}

public struct VPNService: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public let displayName: String

    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
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

public struct OverlayColorValue: Equatable, Sendable {
    public let hex: String
    public let alpha: Double

    public init(hex: String, alpha: Double) {
        self.hex = hex
        self.alpha = alpha
    }
}

public struct AppSettings: Codable, Sendable {
    public var selectedServiceID: String?
    public var overlayEnabled: Bool
    public var overlayThickness: Double
    public var connectedColorHex: String
    public var connectedAlpha: Double
    public var disconnectedColorHex: String
    public var disconnectedAlpha: Double
    public var transitioningColorHex: String
    public var transitioningAlpha: Double
    public var unknownColorHex: String
    public var unknownAlpha: Double
    public var startMonitoringOnLaunch: Bool

    public init(
        selectedServiceID: String? = nil,
        overlayEnabled: Bool = true,
        overlayThickness: Double = 6,
        connectedColorHex: String = "#22C55E",
        connectedAlpha: Double = 0.9,
        disconnectedColorHex: String = "#EF4444",
        disconnectedAlpha: Double = 0.9,
        transitioningColorHex: String = "#F59E0B",
        transitioningAlpha: Double = 0.9,
        unknownColorHex: String = "#6B7280",
        unknownAlpha: Double = 0.9,
        startMonitoringOnLaunch: Bool = true
    ) {
        self.selectedServiceID = selectedServiceID
        self.overlayEnabled = overlayEnabled
        self.overlayThickness = overlayThickness
        self.connectedColorHex = connectedColorHex
        self.connectedAlpha = connectedAlpha
        self.disconnectedColorHex = disconnectedColorHex
        self.disconnectedAlpha = disconnectedAlpha
        self.transitioningColorHex = transitioningColorHex
        self.transitioningAlpha = transitioningAlpha
        self.unknownColorHex = unknownColorHex
        self.unknownAlpha = unknownAlpha
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

    package func alpha(for state: VPNDisplayState) -> Double {
        switch state {
        case .connected:
            connectedAlpha
        case .disconnected:
            disconnectedAlpha
        case .transitioning:
            transitioningAlpha
        case .unknown:
            unknownAlpha
        }
    }

    package mutating func setAlpha(_ alpha: Double, for state: VPNDisplayState) {
        switch state {
        case .connected:
            connectedAlpha = alpha
        case .disconnected:
            disconnectedAlpha = alpha
        case .transitioning:
            transitioningAlpha = alpha
        case .unknown:
            unknownAlpha = alpha
        }
    }
}
