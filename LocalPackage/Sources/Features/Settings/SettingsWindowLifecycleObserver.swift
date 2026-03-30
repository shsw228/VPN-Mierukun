import AppKit
import SwiftUI

struct SettingsWindowLifecycleObserver: NSViewRepresentable {
    let preferredContentSize: CGSize
    let onShow: () -> Void
    let onHide: () -> Void

    func makeNSView(context: Context) -> WindowObserverView {
        let view = WindowObserverView()
        view.onShow = onShow
        view.onHide = onHide
        view.preferredContentSize = preferredContentSize
        return view
    }

    func updateNSView(_ nsView: WindowObserverView, context: Context) {
        nsView.onShow = onShow
        nsView.onHide = onHide
        nsView.preferredContentSize = preferredContentSize
        nsView.refreshVisibility()
        nsView.schedulePreferredContentSizeApplication(animated: true)
    }
}

final class WindowObserverView: NSView {
    var onShow: (() -> Void)?
    var onHide: (() -> Void)?
    var preferredContentSize = CGSize(width: 420, height: 260)
    var activationPolicyController = SettingsAppActivationPolicyController.shared

    private weak var observedWindow: NSWindow?
    private var observers: [NSObjectProtocol] = []
    private var isWindowVisible = false
    private var pendingResizeWorkItem: DispatchWorkItem?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        attachIfNeeded(to: window)
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if newWindow !== observedWindow {
            detachWindow()
        }
    }

    deinit {
        pendingResizeWorkItem?.cancel()
        detachWindow()
    }

    func refreshVisibility() {
        updateVisibility()
    }

    func schedulePreferredContentSizeApplication(animated: Bool) {
        pendingResizeWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.applyPreferredContentSizeIfNeeded(animated: animated)
        }

        pendingResizeWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }

    private func applyPreferredContentSizeIfNeeded(animated: Bool) {
        guard let window = observedWindow else {
            return
        }

        let targetFrame = window.frameRect(forContentRect: NSRect(origin: .zero, size: preferredContentSize))
        let widthDelta = abs(window.frame.width - targetFrame.width)
        let heightDelta = abs(window.frame.height - targetFrame.height)

        guard widthDelta > 1 || heightDelta > 1 else {
            return
        }

        var newFrame = window.frame
        newFrame.origin.x += (newFrame.width - targetFrame.width) / 2
        newFrame.origin.y += newFrame.height - targetFrame.height
        newFrame.size = targetFrame.size
        window.setFrame(newFrame, display: true, animate: animated)
    }

    private func attachIfNeeded(to window: NSWindow?) {
        guard observedWindow !== window else {
            updateVisibility()
            return
        }

        detachWindow()
        observedWindow = window

        guard let window else {
            return
        }

        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { [weak self] _ in
                self?.updateVisibility()
            },
            center.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in
                self?.updateVisibility()
            },
            center.addObserver(forName: NSWindow.didMiniaturizeNotification, object: window, queue: .main) { [weak self] _ in
                self?.updateVisibility()
            },
            center.addObserver(forName: NSWindow.didDeminiaturizeNotification, object: window, queue: .main) { [weak self] _ in
                self?.updateVisibility()
            },
            center.addObserver(forName: NSWindow.didChangeOcclusionStateNotification, object: window, queue: .main) { [weak self] _ in
                self?.updateVisibility()
            },
            center.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.isWindowVisible = false
                    self?.activationPolicyController.update(isShowingSettings: false)
                    self?.onHide?()
                }
            }
        ]

        DispatchQueue.main.async { [weak self] in
            self?.updateVisibility()
            self?.schedulePreferredContentSizeApplication(animated: false)
        }
    }

    private func detachWindow() {
        pendingResizeWorkItem?.cancel()
        pendingResizeWorkItem = nil
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        observedWindow = nil
        if isWindowVisible {
            isWindowVisible = false
            activationPolicyController.update(isShowingSettings: false)
            onHide?()
        }
    }

    private func updateVisibility() {
        let visible = observedWindow?.isVisible == true && observedWindow?.isMiniaturized != true
        guard visible != isWindowVisible else {
            return
        }

        isWindowVisible = visible
        if visible {
            activationPolicyController.update(isShowingSettings: true)
            onShow?()
        } else {
            activationPolicyController.update(isShowingSettings: false)
            onHide?()
        }
    }
}
