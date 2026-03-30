# Homebrew tap 配布

## 方針
- 配布物は GitHub Releases に `VPN-Mierukun-<version>.zip` として公開する
- Homebrew は `formula` ではなく `cask` で配布する
- `tap` リポジトリは別リポジトリとして持つ

## 想定構成
- アプリ本体: `shsw228/VPN-Mierukun`
- tap: `shsw228/homebrew-tap`
- cask 配置先: `Casks/vpn-mierukun.rb`

インストール例:

```bash
brew tap shsw228/tap
brew install --cask vpn-mierukun
```

または 1 コマンドで:

```bash
brew install --cask shsw228/tap/vpn-mierukun
```

## リリース手順
1. Xcode 側の `MARKETING_VERSION` と `CURRENT_PROJECT_VERSION` を更新する
2. `git tag v<version>` を push する
3. GitHub Actions の `Release Homebrew` が ZIP と checksum と cask を release asset として公開する

## tap 自動更新
`release-homebrew.yml` は、以下が設定されている場合のみ tap リポジトリを自動更新する。

- Repository variable: `HOMEBREW_TAP_REPOSITORY`
  - 例: `shsw228/homebrew-tap`
- Repository secret: `HOMEBREW_TAP_TOKEN`
  - tap リポジトリへ push できる PAT

未設定の場合でも、release asset に出力される `vpn-mierukun.rb` を tap リポジトリの `Casks/` に手動で置けばよい。

## ローカル確認
release artifact をローカル生成:

```bash
./scripts/homebrew/build-release-artifacts.sh 0.1.2 ./dist
```

cask の構文確認:

```bash
ruby -c ./dist/vpn-mierukun.rb
```

ローカル tap へ反映:

```bash
./scripts/homebrew/sync-tap-repo.sh ./dist/vpn-mierukun.rb ../homebrew-tap 0.1.2
```
