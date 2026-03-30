import Foundation
import VPNMierukunInfrastructure
import VPNMierukunServices
import VPNMierukunSharedModels

@MainActor
public final class VPNMonitoringStore: ObservableObject {
    public static let shared = VPNMonitoringStore()

    @Published public private(set) var snapshot: VPNStatusSnapshot = .initial
    @Published public private(set) var availableServices: [VPNService] = []
    @Published public private(set) var isMonitoring = false
    @Published public private(set) var settings: AppSettings
    @Published public private(set) var lastErrorMessage: String?
    @Published public private(set) var isShowingSettingsPreview = false
    @Published public private(set) var previewColorState: VPNDisplayState?

    private let provider: any VPNStatusProviding
    private let settingsPersistence: any AppSettingsPersisting
    private let overlayManager: OverlayManager
    private var monitorTask: Task<Void, Never>?

    init(
        provider: any VPNStatusProviding = SystemConfigurationVPNStatusProvider(),
        settingsPersistence: any AppSettingsPersisting = XDGConfigAppSettingsPersistence()
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
            serviceName: selectedServiceDisplayName,
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

    public func beginSettingsPreview() {
        guard !isShowingSettingsPreview else {
            return
        }

        isShowingSettingsPreview = true
        applyOverlay()
    }

    public func endSettingsPreview() {
        guard isShowingSettingsPreview else {
            return
        }

        isShowingSettingsPreview = false
        previewColorState = nil
        overlayManager.hidePreview()
        applyOverlay()
    }

    public var selectedServiceDisplayName: String? {
        selectedService?.displayName
    }

    public func updateSelectedServiceID(_ serviceID: String?) {
        let previousServiceID = settings.selectedServiceID
        settings.selectedServiceID = serviceID
        if previousServiceID != serviceID {
            persistSettings()
        }
        refreshNow()
    }

    public func updateOverlayEnabled(_ enabled: Bool) {
        settings.overlayEnabled = enabled
        persistSettings()
        applyOverlay()
    }

    public func updateOverlayThickness(_ thickness: Double) {
        guard settings.overlayThickness != thickness else {
            return
        }

        settings.overlayThickness = thickness
        persistSettings()
        applyOverlay()
    }

    public func updateStartMonitoringOnLaunch(_ enabled: Bool) {
        settings.startMonitoringOnLaunch = enabled
        persistSettings()
    }

    public func updateColorHex(_ hex: String, for state: VPNDisplayState) {
        guard let normalizedHex = normalizedHexColor(from: hex),
              settings.colorHex(for: state) != normalizedHex else {
            return
        }

        settings.setColorHex(normalizedHex, for: state)
        persistSettings()
        applyOverlay()
    }

    public func updateColor(_ color: OverlayColorValue, for state: VPNDisplayState) {
        guard settings.colorHex(for: state) != color.hex ||
              settings.alpha(for: state) != color.alpha else {
            return
        }

        settings.setColorHex(color.hex, for: state)
        settings.setAlpha(color.alpha, for: state)
        persistSettings()
        applyOverlay()
    }

    public func updateAlpha(_ alpha: Double, for state: VPNDisplayState) {
        guard let normalizedAlpha = normalizedAlpha(alpha),
              settings.alpha(for: state) != normalizedAlpha else {
            return
        }

        settings.setAlpha(normalizedAlpha, for: state)
        persistSettings()
        applyOverlay()
    }

    public func resetOverlayColorsToDefaults() {
        let defaults = AppSettings()
        guard settings.connectedColorHex != defaults.connectedColorHex ||
              settings.connectedAlpha != defaults.connectedAlpha ||
              settings.disconnectedColorHex != defaults.disconnectedColorHex ||
              settings.disconnectedAlpha != defaults.disconnectedAlpha ||
              settings.transitioningColorHex != defaults.transitioningColorHex ||
              settings.transitioningAlpha != defaults.transitioningAlpha ||
              settings.unknownColorHex != defaults.unknownColorHex ||
              settings.unknownAlpha != defaults.unknownAlpha else {
            return
        }

        settings.connectedColorHex = defaults.connectedColorHex
        settings.connectedAlpha = defaults.connectedAlpha
        settings.disconnectedColorHex = defaults.disconnectedColorHex
        settings.disconnectedAlpha = defaults.disconnectedAlpha
        settings.transitioningColorHex = defaults.transitioningColorHex
        settings.transitioningAlpha = defaults.transitioningAlpha
        settings.unknownColorHex = defaults.unknownColorHex
        settings.unknownAlpha = defaults.unknownAlpha
        persistSettings()
        applyOverlay()
    }

    public func colorHex(for state: VPNDisplayState) -> String {
        settings.colorHex(for: state)
    }

    public func alpha(for state: VPNDisplayState) -> Double {
        settings.alpha(for: state)
    }

    public func beginColorPreview(for state: VPNDisplayState) {
        previewColorState = state
        applyOverlay()
    }

    public func endColorPreview() {
        guard previewColorState != nil else {
            return
        }

        previewColorState = nil
        applyOverlay()
    }

    private func refreshServices() async {
        do {
            let services = try await provider.listServices()
            availableServices = services
            synchronizeSelectedService(with: services)
            lastErrorMessage = nil
        } catch {
            availableServices = []
            lastErrorMessage = error.localizedDescription
        }
    }

    private func refreshStatus() async {
        guard let service = selectedService else {
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
            snapshot = try await provider.status(for: service)
            lastErrorMessage = nil
        } catch {
            snapshot = VPNStatusSnapshot(
                state: .unknown,
                serviceName: service.displayName,
                rawStatus: "取得失敗",
                updatedAt: .now
            )
            lastErrorMessage = error.localizedDescription
        }

        applyOverlay()
    }

    private func applyOverlay() {
        if isShowingSettingsPreview {
            let previewColor = previewColorState.map { settings.overlayColor(for: $0) }
            overlayManager.showPreview(
                thickness: CGFloat(settings.overlayThickness),
                color: previewColor
            )
            return
        }

        overlayManager.apply(state: snapshot.state, settings: settings)
    }

    private func persistSettings() {
        settingsPersistence.save(settings)
    }

    private func normalizedHexColor(from rawHex: String) -> String? {
        let sanitized = rawHex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()

        guard sanitized.count == 6,
              sanitized.allSatisfy({ $0.isHexDigit }) else {
            return nil
        }

        return "#\(sanitized)"
    }

    private func normalizedAlpha(_ alpha: Double) -> Double? {
        guard (0...1).contains(alpha) else {
            return nil
        }

        return alpha
    }

    private var selectedService: VPNService? {
        guard let serviceID = settings.selectedServiceID else {
            return nil
        }
        return availableServices.first(where: { $0.id == serviceID })
    }

    private func synchronizeSelectedService(with services: [VPNService]) {
        let resolvedService: VPNService?

        if let selectedServiceID = settings.selectedServiceID {
            resolvedService = services.first(where: { $0.id == selectedServiceID })
        } else {
            resolvedService = services.first
        }

        let previousServiceID = settings.selectedServiceID
        let resolvedServiceID = resolvedService?.id
        settings.selectedServiceID = resolvedServiceID

        if previousServiceID != resolvedServiceID {
            persistSettings()
        }
    }
}
