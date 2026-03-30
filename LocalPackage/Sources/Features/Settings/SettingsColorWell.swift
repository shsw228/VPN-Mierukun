import AppKit
import SwiftUI
import VPNMierukunInfrastructure
import VPNMierukunSharedModels

struct MinimalColorWell: NSViewRepresentable {
    let color: NSColor
    let onBeginPreview: () -> Void
    let onEndPreview: () -> Void
    let onColorChange: (OverlayColorValue) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onBeginPreview: onBeginPreview,
            onEndPreview: onEndPreview,
            onColorChange: onColorChange
        )
    }

    func makeNSView(context: Context) -> PreviewingColorWell {
        let well = PreviewingColorWell()
        well.colorWellStyle = .minimal
        well.controlSize = .small
        well.supportsAlpha = true
        well.isBordered = false
        well.color = color
        well.setContentHuggingPriority(.required, for: .horizontal)
        well.setContentHuggingPriority(.required, for: .vertical)
        well.setContentCompressionResistancePriority(.required, for: .horizontal)
        well.setContentCompressionResistancePriority(.required, for: .vertical)
        well.target = context.coordinator
        well.action = #selector(Coordinator.colorDidChange(_:))
        well.onActivate = {
            context.coordinator.onBeginPreview()
        }
        well.onDeactivate = {
            context.coordinator.onEndPreview()
        }
        return well
    }

    func updateNSView(_ nsView: PreviewingColorWell, context: Context) {
        context.coordinator.onBeginPreview = onBeginPreview
        context.coordinator.onEndPreview = onEndPreview
        context.coordinator.onColorChange = onColorChange
        nsView.onActivate = {
            context.coordinator.onBeginPreview()
        }
        nsView.onDeactivate = {
            context.coordinator.onEndPreview()
        }

        if nsView.color != color {
            nsView.color = color
        }
    }

    final class Coordinator: NSObject {
        var onBeginPreview: () -> Void
        var onEndPreview: () -> Void
        var onColorChange: (OverlayColorValue) -> Void

        init(
            onBeginPreview: @escaping () -> Void,
            onEndPreview: @escaping () -> Void,
            onColorChange: @escaping (OverlayColorValue) -> Void
        ) {
            self.onBeginPreview = onBeginPreview
            self.onEndPreview = onEndPreview
            self.onColorChange = onColorChange
        }

        @objc func colorDidChange(_ sender: NSColorWell) {
            guard let colorValue = OverlayColorSupport.value(from: sender.color) else {
                return
            }

            onColorChange(colorValue)
        }
    }
}

final class PreviewingColorWell: NSColorWell {
    var onActivate: (() -> Void)?
    var onDeactivate: (() -> Void)?
    private var activeStateMonitor: Timer?
    private var popoverWindowCloseObserver: NSObjectProtocol?
    private var popoverWindowResignObserver: NSObjectProtocol?
    private var applicationResignObserver: NSObjectProtocol?
    private var interactionMonitor: Any?
    private var isPreviewActive = false
    private weak var popoverWindow: NSWindow?
    private var activatedAt = Date.distantPast

    override func activate(_ exclusive: Bool) {
        super.activate(exclusive)
        guard !isPreviewActive else {
            startActiveStateMonitor()
            return
        }

        activatedAt = .now
        isPreviewActive = true
        onActivate?()
        startActiveStateMonitor()
    }

    override func deactivate() {
        super.deactivate()
        finishPreviewIfNeeded()
    }

    deinit {
        activeStateMonitor?.invalidate()
        removeObservers()
    }

    private func startActiveStateMonitor() {
        registerApplicationResignObserverIfNeeded()
        registerInteractionMonitorIfNeeded()
        activeStateMonitor?.invalidate()
        activeStateMonitor = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            self.updatePopoverWindowReference()
            self.finishPreviewIfPickerClosed()
        }
    }

    private func finishPreviewIfNeeded() {
        guard isPreviewActive else {
            activeStateMonitor?.invalidate()
            activeStateMonitor = nil
            return
        }

        isPreviewActive = false
        activeStateMonitor?.invalidate()
        activeStateMonitor = nil
        popoverWindow = nil
        removeObservers()
        onDeactivate?()
    }

    private func finishPreviewIfPickerClosed(afterInteractionInHostWindow: Bool = false) {
        if !isActive {
            finishPreviewIfNeeded()
            return
        }

        if let popoverWindow {
            if !popoverWindow.isVisible {
                finishPreviewIfNeeded()
            }
            return
        }

        guard afterInteractionInHostWindow,
              Date.now.timeIntervalSince(activatedAt) > 0.2 else {
            return
        }

        finishPreviewIfNeeded()
    }

    private func updatePopoverWindowReference() {
        guard let candidate = NSApp.windows.first(where: isColorPickerWindow(_:)) else {
            return
        }

        guard popoverWindow !== candidate else {
            return
        }

        popoverWindow = candidate
        if let popoverWindowCloseObserver {
            NotificationCenter.default.removeObserver(popoverWindowCloseObserver)
        }
        if let popoverWindowResignObserver {
            NotificationCenter.default.removeObserver(popoverWindowResignObserver)
        }

        popoverWindowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: candidate,
            queue: .main
        ) { [weak self] _ in
            self?.finishPreviewIfNeeded()
        }

        popoverWindowResignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: candidate,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.finishPreviewIfPickerClosed()
            }
        }
    }

    private func isColorPickerWindow(_ window: NSWindow) -> Bool {
        guard window !== self.window, window.isVisible else {
            return false
        }

        let className = NSStringFromClass(type(of: window)).lowercased()
        if className.contains("popover") || className.contains("color") {
            return true
        }

        return window is NSPanel
    }

    private func registerApplicationResignObserverIfNeeded() {
        guard applicationResignObserver == nil else {
            return
        }

        applicationResignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.finishPreviewIfNeeded()
        }
    }

    private func registerInteractionMonitorIfNeeded() {
        guard interactionMonitor == nil else {
            return
        }

        interactionMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown]) { [weak self] event in
            guard let self else {
                return event
            }

            if event.type == .keyDown {
                DispatchQueue.main.async {
                    self.finishPreviewIfPickerClosed(afterInteractionInHostWindow: true)
                }
                return event
            }

            guard event.window === self.window else {
                return event
            }

            let point = self.convert(event.locationInWindow, from: nil)
            guard !self.bounds.contains(point) else {
                return event
            }

            DispatchQueue.main.async {
                self.finishPreviewIfPickerClosed(afterInteractionInHostWindow: true)
            }
            return event
        }
    }

    private func removeObservers() {
        if let popoverWindowCloseObserver {
            NotificationCenter.default.removeObserver(popoverWindowCloseObserver)
            self.popoverWindowCloseObserver = nil
        }
        if let popoverWindowResignObserver {
            NotificationCenter.default.removeObserver(popoverWindowResignObserver)
            self.popoverWindowResignObserver = nil
        }
        if let applicationResignObserver {
            NotificationCenter.default.removeObserver(applicationResignObserver)
            self.applicationResignObserver = nil
        }
        if let interactionMonitor {
            NSEvent.removeMonitor(interactionMonitor)
            self.interactionMonitor = nil
        }
    }
}
