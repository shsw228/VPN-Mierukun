import SwiftUI
import VPNMierukunSharedModels

struct VPNStatusMenuBarPresenter: View {
    let snapshot: VPNStatusSnapshot
    let selectedServiceName: String?
    @Binding var overlayEnabled: Bool
    @Binding var startMonitoringOnLaunch: Bool
    let isMonitoring: Bool
    let errorMessage: String?
    let onToggleMonitoring: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(snapshot.state.title, systemImage: snapshot.state.symbolName)
                .font(.headline)
                .foregroundStyle(statusColor)

            Text(snapshot.rawStatus)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let selectedServiceName {
                Text("対象: \(selectedServiceName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Toggle("オーバーレイを表示", isOn: $overlayEnabled)
            Toggle("起動時に監視開始", isOn: $startMonitoringOnLaunch)

            HStack {
                Button(isMonitoring ? "監視停止" : "監視開始", action: onToggleMonitoring)
                Button("手動更新", action: onRefresh)
            }

            SettingsLink {
                Text("設定を開く")
            }

            if let errorMessage {
                Divider()
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(14)
        .frame(width: 280)
    }

    private var statusColor: Color {
        switch snapshot.state {
        case .connected:
            .green
        case .disconnected:
            .red
        case .transitioning:
            .orange
        case .unknown:
            .secondary
        }
    }
}
