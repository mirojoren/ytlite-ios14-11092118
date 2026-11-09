#!/bin/bash
# Builds an unsigned iOS 14 IPA without an .xcodeproj.
# Requires macOS + Xcode command line tools. Run: ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

rm -rf Payload YTLite-unsigned.ipa
mkdir -p Payload/YTLite.app
APP="Payload/YTLite.app"

echo "== toolchain =="
xcodebuild -version 2>/dev/null || true
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
echo "SDK: $SDK"

cp Info.plist "$APP/Info.plist"
printf 'APPL????' > "$APP/PkgInfo"

if [ -f icon.b64 ]; then
  python3 -c "import base64;open('$APP/Icon.png','wb').write(base64.b64decode(open('icon.b64').read()))" \
    || base64 -D -i icon.b64 -o "$APP/Icon.png" \
    || echo "warning: icon generation failed, continuing without icon"
fi

echo "== compiling =="
if ! swiftc -sdk "$SDK" -target arm64-apple-ios14.0 -o "$APP/YTLite" App.swift; then
  echo "retrying with -parse-as-library"
  swiftc -sdk "$SDK" -target arm64-apple-ios14.0 -parse-as-library -o "$APP/YTLite" App.swift
fi
chmod 755 "$APP/YTLite"

echo "== verifying =="
file "$APP/YTLite"
file "$APP/YTLite" | grep -qi arm64 || { echo "ERROR: binary is not arm64"; exit 1; }
otool -l "$APP/YTLite" | grep -A4 LC_BUILD_VERSION || true

echo "== packaging =="
zip -qry YTLite-unsigned.ipa Payload
unzip -l YTLite-unsigned.ipa
echo "DONE: $(wc -c < YTLite-unsigned.ipa) bytes"
