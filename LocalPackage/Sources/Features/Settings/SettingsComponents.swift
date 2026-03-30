import AppKit
import SwiftUI
import VPNMierukunInfrastructure
import VPNMierukunSharedModels

struct SettingsTabContent<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        LabeledContent(title) {
            Text(value)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer(minLength: 12)
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OverlayThicknessField: View {
    @Binding var thickness: Double

    @FocusState private var isFocused: Bool
    @State private var draft: String

    init(thickness: Binding<Double>) {
        _thickness = thickness
        _draft = State(initialValue: Self.formattedThickness(from: thickness.wrappedValue))
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField("", text: $draft)
                .frame(width: 64)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit(commitDraft)
            Text("px")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .onChange(of: draft) { _, newValue in
            previewDraft(newValue)
        }
        .onChange(of: isFocused) { wasFocused, isFocused in
            if wasFocused && !isFocused {
                commitDraft()
            }
        }
        .onChange(of: thickness) { _, newValue in
            if !isFocused {
                draft = Self.formattedThickness(from: newValue)
            }
        }
    }

    private func previewDraft(_ rawValue: String) {
        guard let previewThickness = Self.validThickness(from: rawValue) else {
            return
        }

        thickness = previewThickness
    }

    private func commitDraft() {
        guard let normalizedThickness = Self.validThickness(from: draft) else {
            draft = Self.formattedThickness(from: thickness)
            return
        }

        thickness = normalizedThickness
        draft = Self.formattedThickness(from: normalizedThickness)
    }

    private static func validThickness(from rawValue: String) -> Double? {
        guard let value = Int(rawValue.trimmingCharacters(in: .whitespacesAndNewlines)),
              value > 0 else {
            return nil
        }

        return Double(value)
    }

    private static func formattedThickness(from thickness: Double) -> String {
        String(Int(thickness.rounded()))
    }
}

struct ColorSettingRow: View {
    let title: String
    let state: VPNDisplayState
    @Binding var colorHex: String
    @Binding var alpha: Double
    let onBeginPreview: (VPNDisplayState) -> Void
    let onEndPreview: () -> Void
    let onUpdateColor: (VPNDisplayState, OverlayColorValue) -> Void

    init(
        title: String,
        state: VPNDisplayState,
        colorHex: Binding<String>,
        alpha: Binding<Double>,
        onBeginPreview: @escaping (VPNDisplayState) -> Void,
        onEndPreview: @escaping () -> Void,
        onUpdateColor: @escaping (VPNDisplayState, OverlayColorValue) -> Void
    ) {
        self.title = title
        self.state = state
        _colorHex = colorHex
        _alpha = alpha
        self.onBeginPreview = onBeginPreview
        self.onEndPreview = onEndPreview
        self.onUpdateColor = onUpdateColor
    }

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Text(displayedColorCode)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(width: 88, alignment: .trailing)

                MinimalColorWell(
                    color: nsColor,
                    onBeginPreview: {
                        onBeginPreview(state)
                    },
                    onEndPreview: onEndPreview,
                    onColorChange: { color in
                        onUpdateColor(state, color)
                    }
                )
                .frame(width: 40, height: 20)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var displayedColorCode: String {
        EditableOverlayColor(hex: colorHex, alpha: alpha).displayedCode
    }

    private var nsColor: NSColor {
        OverlayColorSupport.color(hex: colorHex, alpha: alpha)
    }
}

private struct EditableOverlayColor {
    let displayedCode: String

    init(hex: String, alpha: Double) {
        displayedCode = OverlayColorSupport.rgbaHexString(hex: hex, alpha: alpha)
    }
}
