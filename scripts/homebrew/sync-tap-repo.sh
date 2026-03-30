#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "usage: $0 <cask-file> <tap-dir> [version]" >&2
  exit 1
fi

CASK_FILE="$1"
TAP_DIR="$2"
VERSION="${3:-}"

if [ ! -f "${CASK_FILE}" ]; then
  echo "cask file not found: ${CASK_FILE}" >&2
  exit 1
fi

mkdir -p "${TAP_DIR}/Casks"
cp "${CASK_FILE}" "${TAP_DIR}/Casks/vpn-mierukun.rb"

if [ -d "${TAP_DIR}/.git" ]; then
  (
    cd "${TAP_DIR}"

    if git diff --quiet -- Casks/vpn-mierukun.rb; then
      exit 0
    fi

    git add Casks/vpn-mierukun.rb

    if [ -n "${VERSION}" ]; then
      git commit -m "[chore] VPN-Mierukun ${VERSION} の cask を更新"
    else
      git commit -m "[chore] VPN-Mierukun の cask を更新"
    fi
  )
fi
