import SwiftUI
import VPNMierukunSharedModels

struct VPNSettingsPresenter: View {
    let availableServices: [String]
    @Binding var selectedServiceName: String
    @Binding var startMonitoringOnLaunch: Bool
    @Binding var overlayEnabled: Bool
    @Binding var overlayThickness: Double
    @Binding var connectedColorHex: String
    @Binding var disconnectedColorHex: String
    @Binding var transitioningColorHex: String
    @Binding var unknownColorHex: String
    let snapshot: VPNStatusSnapshot

    var body: some View {
        Form {
            Section("監視") {
                Picker("VPN サービス", selection: $selectedServiceName) {
                    Text("未選択").tag("")
                    ForEach(availableServices, id: \.self) { service in
                        Text(service).tag(service)
                    }
                }

                HStack {
                    Text("利用可能サービス数")
                    Spacer()
                    Text("\(availableServices.count)")
                        .foregroundStyle(.secondary)
                }

                Toggle("起動時に監視を開始", isOn: $startMonitoringOnLaunch)
            }

            Section("オーバーレイ") {
                Toggle("オーバーレイを有効化", isOn: $overlayEnabled)

                VStack(alignment: .leading) {
                    Text("線幅: \(Int(overlayThickness)) px")
                    Slider(value: $overlayThickness, in: 2...20, step: 1)
                }
            }

            Section("色設定") {
                colorField(title: "接続中", text: $connectedColorHex)
                colorField(title: "未接続", text: $disconnectedColorHex)
                colorField(title: "切り替え中", text: $transitioningColorHex)
                colorField(title: "不明", text: $unknownColorHex)
            }

            Section("状態") {
                HStack {
                    Text("現在状態")
                    Spacer()
                    Text(snapshot.state.title)
                }

                HStack {
                    Text("生ステータス")
                    Spacer()
                    Text(snapshot.rawStatus)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func colorField(title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textFieldStyle(.roundedBorder)
    }
}
