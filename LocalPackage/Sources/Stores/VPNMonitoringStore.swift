import Foundation
import VPNMierukunInfrastructure
import VPNMierukunServices
import VPNMierukunSharedModels

@MainActor
public final class VPNMonitoringStore: ObservableObject {
    public static let shared = VPNMonitoringStore()

    @Published public private(set) var snapshot: VPNStatusSnapshot = .initial
    @Published public private(set) var availableServices: [String] = []
    @Published public private(set) var isMonitoring = false
    @Published public private(set) var settings: AppSettings
    @Published public private(set) var lastErrorMessage: String?

    private let provider: any VPNStatusProviding
    private let settingsPersistence: any AppSettingsPersisting
    private let overlayManager: OverlayManager
    private var monitorTask: Task<Void, Never>?

    init(
        provider: any VPNStatusProviding = ScutilVPNStatusProvider(),
        settingsPersistence: any AppSettingsPersisting = UserDefaultsAppSettingsPersistence()
    ) {
        self.provider = provider
        self.settingsPersistence = settingsPersistence
        self.overlayManager = OverlayManager()
        self.settings = settingsPersistence.load()
    }

    deinit {
        monitorTask?.cancel()
    }

    public func start() {
        Task {
            await refreshServices()
            if settings.startMonitoringOnLaunch {
                startMonitoring()
            } else {
                applyOverlay()
            }
        }
    }

    public func stop() {
        monitorTask?.cancel()
        monitorTask = nil
        isMonitoring = false
        overlayManager.hideAll()
    }

    public func startMonitoring() {
        guard monitorTask == nil else {
            return
        }

        isMonitoring = true
        monitorTask = Task { [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                await refreshStatus()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    public func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
        isMonitoring = false
        snapshot = VPNStatusSnapshot(
            state: .unknown,
            serviceName: settings.selectedServiceName,
            rawStatus: "監視停止中",
            updatedAt: .now
        )
        applyOverlay()
    }

    public func refreshNow() {
        Task {
            await refreshServices()
            await refreshStatus()
        }
    }

    public func refreshOverlayForCurrentScreens() {
        applyOverlay()
    }

    public func updateSelectedService(_ serviceName: String?) {
        settings.selectedServiceName = serviceName
        persistSettings()
        refreshNow()
    }

    public func updateOverlayEnabled(_ enabled: Bool) {
        settings.overlayEnabled = enabled
        persistSettings()
        applyOverlay()
    }

    public func updateOverlayThickness(_ thickness: Double) {
        settings.overlayThickness = thickness
        persistSettings()
        applyOverlay()
    }

    public func updateStartMonitoringOnLaunch(_ enabled: Bool) {
        settings.startMonitoringOnLaunch = enabled
        persistSettings()
    }

    public func updateColorHex(_ hex: String, for state: VPNDisplayState) {
        settings.setColorHex(hex, for: state)
        persistSettings()
        applyOverlay()
    }

    public func colorHex(for state: VPNDisplayState) -> String {
        settings.colorHex(for: state)
    }

    private func refreshServices() async {
        do {
            let services = try await provider.listServices()
            availableServices = services

            if let selected = settings.selectedServiceName, !services.contains(selected) {
                settings.selectedServiceName = services.first
                persistSettings()
            } else if settings.selectedServiceName == nil {
                settings.selectedServiceName = services.first
                persistSettings()
            }

            lastErrorMessage = nil
        } catch {
            availableServices = []
            lastErrorMessage = error.localizedDescription
        }
    }

    private func refreshStatus() async {
        guard let serviceName = settings.selectedServiceName, !serviceName.isEmpty else {
            snapshot = VPNStatusSnapshot(
                state: .unknown,
                serviceName: nil,
                rawStatus: "監視対象 VPN を選択してください",
                updatedAt: .now
            )
            applyOverlay()
            return
        }

        do {
            snapshot = try await provider.status(for: serviceName)
            lastErrorMessage = nil
        } catch {
            snapshot = VPNStatusSnapshot(
                state: .unknown,
                serviceName: serviceName,
                rawStatus: "取得失敗",
                updatedAt: .now
            )
            lastErrorMessage = error.localizedDescription
        }

        applyOverlay()
    }

    private func applyOverlay() {
        overlayManager.apply(state: snapshot.state, settings: settings)
    }

    private func persistSettings() {
        settingsPersistence.save(settings)
    }
}
