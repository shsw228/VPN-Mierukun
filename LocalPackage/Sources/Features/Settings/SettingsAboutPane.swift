import AppKit
import LicenseList
import SwiftUI

struct AboutSettingsPane: View {
    private let metadata = AppMetadata.current
    @State private var isShowingLicenses = false

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(spacing: 4) {
                Text(metadata.displayName)
                    .font(.title3.weight(.semibold))
                Text("バージョン \(metadata.version) (\(metadata.build))")
                    .foregroundStyle(.secondary)
                Text(metadata.bundleIdentifier)
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
            }
            .multilineTextAlignment(.center)

            Text("VPN の接続状態を macOS 画面周囲のオーバーレイで可視化します。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            Button("ライセンスを表示") {
                isShowingLicenses = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .padding(20)
        .sheet(isPresented: $isShowingLicenses) {
            LicenseSheet()
        }
    }
}

private struct LicenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LicenseListView()
                .licenseListViewStyle(.automatic)
                .licenseViewStyle(.plain)
                .navigationTitle("ライセンス")
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .frame(minWidth: 640, minHeight: 520)
    }
}

private struct AppMetadata {
    let displayName: String
    let version: String
    let build: String
    let bundleIdentifier: String

    static let current = AppMetadata(
        displayName: Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "VPN-Mierukun",
        version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0",
        build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-",
        bundleIdentifier: Bundle.main.bundleIdentifier ?? "-"
    )
}
