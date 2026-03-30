#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "usage: $0 <version> <sha256> [owner/repo]" >&2
  exit 1
fi

VERSION="$1"
SHA256="$2"
REPOSITORY="${3:-${GITHUB_REPOSITORY:-shsw228/VPN-Mierukun}}"
RELEASE_TAG="${RELEASE_TAG:-v${VERSION}}"

cat <<EOF
# typed: strict
# frozen_string_literal: true

cask "vpn-mierukun" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/${REPOSITORY}/releases/download/${RELEASE_TAG}/VPN-Mierukun-#{version}.zip"
  name "VPN-Mierukun"
  desc "Visualize VPN connection status with a screen-edge overlay"
  homepage "https://github.com/${REPOSITORY}"

  depends_on macos: ">= :sonoma"

  app "VPN-Mierukun.app"

  uninstall quit: "com.shsw228.vpn-mierukun"

  zap trash: "~/Library/Preferences/com.shsw228.vpn-mierukun.plist"
end
EOF
