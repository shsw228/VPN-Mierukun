import SwiftUI
import VPNMierukunSharedModels

struct VPNSettingsPresenter: View {
    let availableServices: [VPNService]
    @Binding var selectedTab: SettingsTab
    @Binding var selectedServiceID: String
    @Binding var startMonitoringOnLaunch: Bool
    @Binding var overlayEnabled: Bool
    @Binding var overlayThickness: Double
    @Binding var connectedColorHex: String
    @Binding var connectedAlpha: Double
    @Binding var disconnectedColorHex: String
    @Binding var disconnectedAlpha: Double
    @Binding var transitioningColorHex: String
    @Binding var transitioningAlpha: Double
    @Binding var unknownColorHex: String
    @Binding var unknownAlpha: Double
    let onBeginColorPreview: (VPNDisplayState) -> Void
    let onEndColorPreview: () -> Void
    let onUpdateColor: (VPNDisplayState, OverlayColorValue) -> Void
    let onResetOverlayColors: () -> Void
    let snapshot: VPNStatusSnapshot

    var body: some View {
        TabView(selection: $selectedTab) {
            generalPane
                .tabItem {
                    Label("一般", systemImage: "gearshape")
                }
                .tag(SettingsTab.general)

            overlayPane
                .tabItem {
                    Label("オーバーレイ", systemImage: "rectangle.dashed")
                }
                .tag(SettingsTab.overlay)

            aboutPane
                .tabItem {
                    Label("このアプリについて", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
    }

    private var generalPane: some View {
        SettingsTabContent {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    SettingsToggleRow(title: "VPN-Mierukun を有効化", isOn: $overlayEnabled)
                    SettingsToggleRow(title: "起動時に監視を開始", isOn: $startMonitoringOnLaunch)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent("VPN サービス") {
                        Picker("", selection: $selectedServiceID) {
                            Text("未選択").tag("")
                            ForEach(availableServices) { service in
                                Text(service.displayName).tag(service.id)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 208, alignment: .trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    SettingsValueRow(title: "検出数", value: "\(availableServices.count) 件")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    SettingsValueRow(title: "現在状態", value: snapshot.state.title)
                    SettingsValueRow(title: "生ステータス", value: snapshot.rawStatus)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var overlayPane: some View {
        SettingsTabContent {
            GroupBox {
                LabeledContent("線幅") {
                    OverlayThicknessField(thickness: $overlayThickness)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    ColorSettingRow(
                        title: "接続中",
                        state: .connected,
                        colorHex: $connectedColorHex,
                        alpha: $connectedAlpha,
                        onBeginPreview: onBeginColorPreview,
                        onEndPreview: onEndColorPreview,
                        onUpdateColor: onUpdateColor
                    )
                    ColorSettingRow(
                        title: "未接続",
                        state: .disconnected,
                        colorHex: $disconnectedColorHex,
                        alpha: $disconnectedAlpha,
                        onBeginPreview: onBeginColorPreview,
                        onEndPreview: onEndColorPreview,
                        onUpdateColor: onUpdateColor
                    )
                    ColorSettingRow(
                        title: "切り替え中",
                        state: .transitioning,
                        colorHex: $transitioningColorHex,
                        alpha: $transitioningAlpha,
                        onBeginPreview: onBeginColorPreview,
                        onEndPreview: onEndColorPreview,
                        onUpdateColor: onUpdateColor
                    )
                    ColorSettingRow(
                        title: "不明",
                        state: .unknown,
                        colorHex: $unknownColorHex,
                        alpha: $unknownAlpha,
                        onBeginPreview: onBeginColorPreview,
                        onEndPreview: onEndColorPreview,
                        onUpdateColor: onUpdateColor
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Spacer()
                Button("デフォルトに戻す", action: onResetOverlayColors)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var aboutPane: some View {
        AboutSettingsPane()
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
