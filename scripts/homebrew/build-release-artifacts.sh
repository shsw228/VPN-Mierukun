#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "usage: $0 <version> <output-dir> [owner/repo]" >&2
  exit 1
fi

VERSION="$1"
OUTPUT_DIR="$2"
REPOSITORY="${3:-${GITHUB_REPOSITORY:-shsw228/VPN-Mierukun}}"

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT_PATH="${ROOT_DIR}/VPN-Mierukun.xcodeproj"
SCHEME="VPN-Mierukun"
APP_NAME="VPN-Mierukun"
DERIVED_DATA_PATH="${ROOT_DIR}/build/homebrew-release"
APP_PATH="${DERIVED_DATA_PATH}/Build/Products/Release/${APP_NAME}.app"
ZIP_PATH="${OUTPUT_DIR}/${APP_NAME}-${VERSION}.zip"
CHECKSUM_PATH="${ZIP_PATH}.sha256"
CASK_PATH="${OUTPUT_DIR}/vpn-mierukun.rb"

rm -rf "${DERIVED_DATA_PATH}" "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

xcodebuild \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -destination "platform=macOS" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=NO \
  ARCHS="arm64 x86_64" \
  build

if [ ! -d "${APP_PATH}" ]; then
  echo "built app not found: ${APP_PATH}" >&2
  exit 1
fi

BINARY_PATH="${APP_PATH}/Contents/MacOS/${APP_NAME}"
INFO_PLIST_PATH="${APP_PATH}/Contents/Info.plist"
APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST_PATH}")"
APP_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${INFO_PLIST_PATH}")"

if [ "${APP_VERSION}" != "${VERSION}" ]; then
  echo "version mismatch: requested ${VERSION}, app bundle has ${APP_VERSION}" >&2
  exit 1
fi

echo "Built architectures: $(lipo -archs "${BINARY_PATH}")"
echo "Built version: ${APP_VERSION} (${APP_BUILD})"

ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${ZIP_PATH}"
(cd "${OUTPUT_DIR}" && shasum -a 256 "$(basename "${ZIP_PATH}")") | tee "${CHECKSUM_PATH}"
SHA256="$(awk '{print $1}' "${CHECKSUM_PATH}")"

RELEASE_TAG="${RELEASE_TAG:-v${VERSION}}" \
  "${ROOT_DIR}/scripts/homebrew/render-cask.sh" "${VERSION}" "${SHA256}" "${REPOSITORY}" > "${CASK_PATH}"

ruby -c "${CASK_PATH}" >/dev/null

if command -v brew >/dev/null 2>&1; then
  brew style "${CASK_PATH}"
fi
