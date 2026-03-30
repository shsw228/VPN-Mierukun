import Foundation
import SystemConfiguration
import VPNMierukunSharedModels

public protocol VPNStatusProviding: Sendable {
    func listServices() async throws -> [VPNService]
    func status(for service: VPNService) async throws -> VPNStatusSnapshot
}

public struct SystemConfigurationVPNStatusProvider: VPNStatusProviding {
    public init() {}

    public func listServices() async throws -> [VPNService] {
        try await Task.detached(priority: .utility) {
            guard let preferences = SCPreferencesCreate(nil, "VPNMierukun" as CFString, nil) else {
                throw providerError("VPN 設定の読み込みに失敗しました")
            }

            let services = (SCNetworkServiceCopyAll(preferences) as? [SCNetworkService]) ?? []
            return services
                .compactMap(makeVPNService(from:))
                .sorted {
                    $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
                }
        }.value
    }

    public func status(for service: VPNService) async throws -> VPNStatusSnapshot {
        try await Task.detached(priority: .utility) {
            guard let connection = SCNetworkConnectionCreateWithServiceID(nil, service.id as CFString, nil, nil) else {
                throw providerError("VPN 接続の作成に失敗しました")
            }

            let status = SCNetworkConnectionGetStatus(connection)
            return VPNStatusSnapshot(
                state: mapDisplayState(from: status),
                serviceName: service.displayName,
                rawStatus: rawStatusText(for: status),
                updatedAt: .now
            )
        }.value
    }

    private func makeVPNService(from service: SCNetworkService) -> VPNService? {
        guard isVPNService(service),
              let serviceID = SCNetworkServiceGetServiceID(service) as String? else {
            return nil
        }

        let name = (SCNetworkServiceGetName(service) as String?)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return VPNService(
            id: serviceID,
            displayName: (name?.isEmpty == false ? name : nil) ?? serviceID
        )
    }

    private func isVPNService(_ service: SCNetworkService) -> Bool {
        guard let rootInterface = SCNetworkServiceGetInterface(service) else {
            return false
        }

        var currentInterface: SCNetworkInterface? = rootInterface
        while let interface = currentInterface {
            if let interfaceType = SCNetworkInterfaceGetInterfaceType(interface) as String?,
               vpnInterfaceTypes.contains(interfaceType) {
                return true
            }
            currentInterface = SCNetworkInterfaceGetInterface(interface)
        }

        return false
    }

    private func mapDisplayState(from status: SCNetworkConnectionStatus) -> VPNDisplayState {
        switch status {
        case .connected:
            .connected
        case .disconnected:
            .disconnected
        case .connecting, .disconnecting:
            .transitioning
        default:
            .unknown
        }
    }

    private func rawStatusText(for status: SCNetworkConnectionStatus) -> String {
        switch status {
        case .connected:
            "Connected"
        case .disconnected:
            "Disconnected"
        case .connecting:
            "Connecting"
        case .disconnecting:
            "Disconnecting"
        default:
            "Invalid"
        }
    }
}

private let vpnInterfaceTypes: Set<String> = [
    kSCNetworkInterfaceTypeIPSec as String,
    kSCNetworkInterfaceTypeL2TP as String,
    kSCNetworkInterfaceTypePPP as String
]

private func providerError(_ message: String) -> NSError {
    NSError(
        domain: "SystemConfigurationVPNStatusProvider",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: message]
    )
}
