#!/bin/bash
# nameless — Liquid Glass build script
#
# Builds the Telegram-iOS target with the Liquid Glass integration included.
# Must be run on macOS 26 Tahoe with Xcode 26.2 and Bazel 8.4.2 installed.
#
# Usage:
#   ./scripts/build_nameless.sh                # debug_sim_arm64 build
#   ./scripts/build_nameless.sh debug_arm64    # device debug build

set -e

CONFIG="${1:-debug_sim_arm64}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Source shell config to pick up TELEGRAM_CODESIGNING_GIT_PASSWORD
if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc" 2>/dev/null || true
fi

echo "==> Building nameless with configuration=$CONFIG"
echo "==> Repo: $REPO_ROOT"

python3 build-system/Make/Make.py \
    --overrideXcodeVersion \
    --cacheDir ~/telegram-bazel-cache \
    build \
    --configurationPath build-system/appstore-configuration.json \
    --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
    --gitCodesigningType development \
    --gitCodesigningUseCurrent \
    --buildNumber=1 \
    --configuration="$CONFIG" \
    --continueOnError

echo ""
echo "==> Build finished."
