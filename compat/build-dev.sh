#!/bin/bash
set -euo pipefail

RUN_TESTS=0
CONFIGURATION=Debug
PRODUCT_NAME='Tinycast Dev'
EXPECTED_BUNDLE_ID=com.tinycast.app.dev
BUILD_CHANNEL=sequoia-dev
VERSION=0.9.7
case "${1:-}" in
    "") ;;
    --test) RUN_TESTS=1 ;;
    --release)
        CONFIGURATION=Release
        PRODUCT_NAME=Tinycast
        EXPECTED_BUNDLE_ID=com.tinycast.app
        BUILD_CHANNEL=sequoia-primary
        VERSION=0.9.7-sequoia.2
        ;;
    *) echo "Usage: bash compat/build-dev.sh [--test | --release]" >&2; exit 64 ;;
esac
if [ "$#" -gt 1 ]; then
    echo "Usage: bash compat/build-dev.sh [--test | --release]" >&2
    exit 64
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

xcodebuild -checkFirstLaunchStatus
xcrun swift --version
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
export PATH="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin:$PATH"

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/tinycast-sequoia-dev.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
git archive HEAD | tar -x -C "$STAGE"
git diff HEAD --binary | git -C "$STAGE" apply --allow-empty -

while IFS= read -r -d '' file; do
    mkdir -p "$STAGE/$(dirname "$file")"
    cp -pP "$file" "$STAGE/$file"
done < <(git ls-files --others --exclude-standard -z -- Tinycast Tinycast.xcodeproj Tests NOTICE.md)

git -C "$STAGE" apply --whitespace=nowarn "$ROOT/compat/macos15.patch"

if [ "$RUN_TESTS" -eq 1 ]; then
    (cd "$STAGE" && ./Scripts/run-tests.sh)
fi

xcodebuild -project "$STAGE/Tinycast.xcodeproj" -scheme Tinycast \
    -configuration "$CONFIGURATION" -derivedDataPath "$ROOT/build/$BUILD_CHANNEL" \
    MACOSX_DEPLOYMENT_TARGET=15.0 ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
    CODE_SIGN_IDENTITY=- MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION=3 build

APP="$ROOT/build/$BUILD_CHANNEL/Build/Products/$CONFIGURATION/$PRODUCT_NAME.app"
PLIST="$APP/Contents/Info.plist"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST")"
MIN_OS="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$PLIST")"
EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$PLIST")"
if [ "$BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ] || [ "$MIN_OS" != 15.0 ]; then
    echo "Unexpected bundle identity or minimum macOS version." >&2
    exit 1
fi
BINARIES=("$APP/Contents/MacOS/$EXECUTABLE" "$APP/Contents/Helpers/FileIndexHelper")
if [ "$CONFIGURATION" = Debug ]; then
    BINARIES+=("$APP/Contents/MacOS/$EXECUTABLE.debug.dylib")
fi
for BINARY in "${BINARIES[@]}"; do
    MIN_BINARY="$(xcrun vtool -arch arm64 -show-build-version "$BINARY" | awk '/minos/{print $2}')"
    if [ "$MIN_BINARY" != 15.0 ]; then
        echo "Unexpected minimum macOS version in $BINARY." >&2
        exit 1
    fi
    STRONG_GLASS="$(xcrun nm -m "$BINARY" \
        | awk '/\(undefined\)/ && /[Gg]lass/ && !/weak/')"
    if [ -n "$STRONG_GLASS" ]; then
        echo "Unexpected required Liquid Glass symbols in $BINARY." >&2
        exit 1
    fi
done
codesign --verify --deep --strict "$APP"
printf '\n%s build: %s\n' "$CONFIGURATION" "$APP"
