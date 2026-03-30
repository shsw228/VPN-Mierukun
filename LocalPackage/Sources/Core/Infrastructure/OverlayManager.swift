import AppKit
import Foundation
import VPNMierukunSharedModels

@MainActor
package final class OverlayManager {
    private enum Edge: CaseIterable {
        case top
        case bottom
        case left
        case right
    }

    private final class OverlayWindow: NSWindow {
        init(frame: NSRect, color: NSColor) {
            super.init(
                contentRect: frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            isReleasedWhenClosed = false
            isOpaque = false
            backgroundColor = .clear
            hasShadow = false
            ignoresMouseEvents = true
            level = .statusBar
            collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

            let view = NSView(frame: frame)
            view.wantsLayer = true
            view.layer?.cornerRadius = 2
            view.layer?.backgroundColor = color.cgColor
            contentView = view
        }

        func updateColor(_ color: NSColor) {
            contentView?.layer?.backgroundColor = color.cgColor
        }
    }

    private var windowsByScreenID: [String: [OverlayWindow]] = [:]
    private var previewTask: Task<Void, Never>?
    private var previewThickness: CGFloat = 6
    private var previewHue: CGFloat = 0
    private var previewColorOverride: NSColor?

    package init() {}

    package func apply(state: VPNDisplayState, settings: AppSettings) {
        guard previewTask == nil else {
            showPreview(thickness: CGFloat(settings.overlayThickness), color: previewColorOverride)
            return
        }

        guard settings.overlayEnabled else {
            hideAll()
            return
        }

        syncWindows(thickness: CGFloat(settings.overlayThickness), color: settings.overlayColor(for: state))
    }

    package func showPreview(thickness: CGFloat, color: NSColor? = nil) {
        previewThickness = thickness
        previewColorOverride = color

        if previewTask == nil {
            previewTask = Task { [weak self] in
                guard let self else {
                    return
                }

                while !Task.isCancelled {
                    syncWindows(thickness: previewThickness, color: activePreviewColor)
                    if previewColorOverride == nil {
                        previewHue = (previewHue + 0.005).truncatingRemainder(dividingBy: 1)
                    }
                    try? await Task.sleep(for: .milliseconds(80))
                }
            }
        } else {
            syncWindows(thickness: previewThickness, color: activePreviewColor)
        }
    }

    package func hidePreview() {
        previewTask?.cancel()
        previewTask = nil
        previewColorOverride = nil
        hideAll()
    }

    package func hideAll() {
        for windows in windowsByScreenID.values {
            for window in windows {
                window.orderOut(nil)
            }
        }
    }

    private func syncWindows(thickness: CGFloat, color: NSColor) {
        let screens = NSScreen.screens
        let activeKeys = Set(screens.compactMap(Self.screenIdentifier(for:)))

        for (key, windows) in windowsByScreenID where !activeKeys.contains(key) {
            for window in windows {
                window.close()
            }
            windowsByScreenID.removeValue(forKey: key)
        }

        for screen in screens {
            guard let identifier = Self.screenIdentifier(for: screen) else {
                continue
            }

            let frames = Self.frames(for: screen.frame, thickness: thickness)
            let windows = windowsByScreenID[identifier] ?? []

            if windows.count != Edge.allCases.count {
                for window in windows {
                    window.close()
                }
                windowsByScreenID[identifier] = frames.map { OverlayWindow(frame: $0, color: color) }
            } else {
                for (window, frame) in zip(windows, frames) {
                    window.setFrame(frame, display: true)
                    window.updateColor(color)
                }
            }

            windowsByScreenID[identifier]?.forEach { window in
                window.updateColor(color)
                window.orderFrontRegardless()
            }
        }
    }

    private static func screenIdentifier(for screen: NSScreen) -> String? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.stringValue
    }

    private static func frames(for screenFrame: NSRect, thickness: CGFloat) -> [NSRect] {
        [
            NSRect(x: screenFrame.minX, y: screenFrame.maxY - thickness, width: screenFrame.width, height: thickness),
            NSRect(x: screenFrame.minX, y: screenFrame.minY, width: screenFrame.width, height: thickness),
            NSRect(x: screenFrame.minX, y: screenFrame.minY, width: thickness, height: screenFrame.height),
            NSRect(x: screenFrame.maxX - thickness, y: screenFrame.minY, width: thickness, height: screenFrame.height)
        ]
    }

    private var activePreviewColor: NSColor {
        if let previewColorOverride {
            return previewColorOverride
        }

        return NSColor(
            calibratedHue: previewHue,
            saturation: 0.8,
            brightness: 0.95,
            alpha: 0.9
        )
    }
}
