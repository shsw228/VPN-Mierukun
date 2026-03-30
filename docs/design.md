# 設計メモ

## 設計方針
- まずは「目で見て即座に分かる」ことを最優先にし、実装難度の高い接続制御や通知連携は後回しにする
- VPN 状態取得の実装は差し替え可能にし、UI と取得ロジックを分離する
- 画面オーバーレイは操作阻害を避けるため、画面全体ではなく各辺の細いウィンドウとして管理する

## 想定ターゲット
- macOS 14 以降
- Swift + SwiftUI を中心にしつつ、オーバーレイ表示のみ AppKit を使う
- メニューバー常駐アプリとして動作させる
- Xcode app target は薄く保ち、実装の大半は `LocalPackage` に置く

## MVP 構成
- `VPNMierukunApp`
  - `@main` のみを持つ薄い app target
- `LocalPackage/VPNMierukunFeature`
  - 実装本体を持つローカル Swift Package

## 現在のディレクトリ構成
```text
LocalPackage/Sources/
├── AppEntry/
├── Core/
│   ├── Infrastructure/
│   ├── Services/
│   └── Stores/
├── Features/
│   ├── MenuBar/
│   └── Settings/
├── Shared/
│   └── Models/
```

## ディレクトリ方針
- README の依存レイヤーと物理配置を合わせる
- `Stores / Services / Infrastructure` は `Core` 配下へまとめ、横断的な中核処理として扱う
- `Features` には UI 機能ごとの Container / Presenter を置く

## Xcode プロジェクト方針
- `.xcodeproj` を正本として扱う
- `LocalPackage` は Swift Package として接続し、内部依存は `Package.swift` で管理する
- Xcode プロジェクト構成の変更は `.xcodeproj` 側へ直接反映する

## 責務分割
- `AppEntry`
  - `VPNMierukunScenes` と `VPNMierukunAppDelegate` を置く
- `Stores`
  - `VPNMonitoringStore` が共有状態、ポーリング、ユースケース調停を担う
- `Services`
  - `ScutilVPNStatusProvider` が VPN 状態取得、`UserDefaultsAppSettingsPersistence` が設定永続化を担う
- `Infrastructure`
  - `OverlayManager` が画面オーバーレイの OS 連携を担う
- `Features/MenuBar`
  - Container が Store と結線し、Presenter が表示を担当する
- `Features/Settings`
  - Container が Binding を組み、Presenter が設定 UI を描画する

## Package 依存関係
- `VPNMierukunFeature`
  - `VPNMierukunStores`
  - `VPNMierukunMenuBarFeature`
  - `VPNMierukunSettingsFeature`
- `VPNMierukunStores`
  - `VPNMierukunSharedModels`
  - `VPNMierukunServices`
  - `VPNMierukunInfrastructure`
- `VPNMierukunMenuBarFeature`
  - `VPNMierukunSharedModels`
  - `VPNMierukunStores`
- `VPNMierukunSettingsFeature`
  - `VPNMierukunSharedModels`
  - `VPNMierukunStores`
- `VPNMierukunServices`
  - `VPNMierukunSharedModels`
- `VPNMierukunInfrastructure`
  - `VPNMierukunSharedModels`

## VPN 状態取得の設計
### 初期案
- MVP では `scutil --nc` を使って macOS に登録済みの VPN サービス一覧と状態を取得する
- 理由は、特定ベンダーの VPN クライアントに閉じず、まずは利用者の既存 VPN を監視対象にしやすいため
- 状態監視はポーリングベースで開始し、初期値は 2 秒間隔を想定する

### 状態マッピング
- `Connected` -> `connected`
- `Disconnected` -> `disconnected`
- `Connecting` / `Disconnecting` / `Reasserting` -> `transitioning`
- その他の取得失敗や未解決状態 -> `unknown`

### 注意点
- `scutil` 出力フォーマットへの依存があるため、パーサは 1 箇所に閉じ込める
- VPN 実装差異により期待どおりの状態が取れない場合に備え、`VPNStatusProvider` を差し替え可能にする
- 将来、より安定した API が必要になった場合でも UI 層へ影響を広げない構成にする

## オーバーレイ表示の設計
### 表示方式
- 各ディスプレイに対して上・下・左・右の 4 本の細い境界ウィンドウを配置する
- 各ウィンドウは透明背景の borderless window とし、色付きビューのみを表示する
- クリック透過を有効化し、通常操作を妨げないようにする

### 追従対象
- 接続中の全ディスプレイ
- ディスプレイ追加・削除
- 解像度変更
- Spaces / フルスクリーン環境

### 管理責務
- `OverlayManager` が NSScreen 一覧から必要なオーバーレイを再構築する
- 状態変更時は既存ウィンドウを再生成せず、色のみ更新する
- 設定変更時は線幅と色を再適用する

## UI 設計
### メニューバー
- 現在状態を色とテキストで表示する
- 監視対象 VPN 名を表示する
- オーバーレイ有効/無効を切り替える
- 手動更新を実行する
- 設定画面を開く
- アプリを終了する

### 設定画面
- 監視対象 VPN サービス選択
- 状態別カラー設定
- オーバーレイ幅設定
- 起動時に監視を開始する設定

## データモデル案
```swift
enum VPNDisplayState: String, Codable {
    case connected
    case disconnected
    case transitioning
    case unknown
}

struct AppSettings: Codable {
    var selectedServiceName: String?
    var overlayEnabled: Bool
    var overlayThickness: Double
    var connectedColorHex: String
    var disconnectedColorHex: String
    var transitioningColorHex: String
    var unknownColorHex: String
    var startMonitoringOnLaunch: Bool
}

struct VPNStatusSnapshot {
    var state: VPNDisplayState
    var serviceName: String?
    var rawStatus: String
    var updatedAt: Date
}
```

## イベントフロー
1. アプリ起動
2. `VPNMierukunAppDelegate` が Store を起動し、画面構成変更監視を登録
3. `VPNMonitoringStore` が設定読み込み後に利用可能 VPN 一覧を取得
4. 監視対象があればポーリング開始
5. 状態更新時に `VPNMonitoringStore` を更新
6. `OverlayManager` と各 Feature Container 経由で UI に反映
7. ディスプレイ構成変更時に overlay を再適用

## 実装順
1. メニューバーアプリの土台を作る
2. `LocalPackage` を app target に接続する
3. `scutil` ベースの VPN 一覧取得・状態取得を実装する
4. 状態ストアとポーリングをつなぐ
5. 単一ディスプレイ向けオーバーレイを実装する
6. マルチディスプレイ対応と設定永続化を追加する

## リスク
- VPN 種類によって `scutil --nc` で十分な状態が取れない可能性がある
- フルスクリーンや Spaces をまたぐオーバーレイの挙動調整が必要
- クリック透過やウィンドウレベル調整で macOS バージョン差異が出る可能性がある
- 将来的に sandbox 制約が課題になる可能性がある

## 当面の次アクション
- `scutil` 出力の実機差分を確認して状態マッピングを補強する
- オーバーレイのフルスクリーン・マルチディスプレイ挙動を実機確認する
- 色設定を HEX 入力からより扱いやすい UI へ改善する
