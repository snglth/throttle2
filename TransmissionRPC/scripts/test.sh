#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p .clang-module-cache .home

export HOME="$ROOT/.home"

export CLANG_MODULE_CACHE_PATH="$ROOT/.clang-module-cache"

SDK_ARGS=()
if [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

if [[ -x "/usr/bin/xcrun" ]]; then
  SDK_PATH="$(/usr/bin/xcrun --sdk macosx --show-sdk-path)"
  SDK_ARGS=(--sdk "$SDK_PATH")
fi

unset SDKROOT || true

exec swift test --disable-sandbox --manifest-cache local "${SDK_ARGS[@]}"
