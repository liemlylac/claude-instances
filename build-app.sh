#!/bin/bash
# Build thành "Claude Instances.app" (chạy trên macOS, cần Xcode Command Line Tools)
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Claude Instances"
EXE="ClaudeInstances"
BUNDLE_ID="local.liem.claudeinstances"
OUT="build/${APP_NAME}.app"

# Icon: tạo lại nếu chưa có (swift scripts/make-icon.swift)
[ -f Resources/AppIcon.icns ] || swift scripts/make-icon.swift

swift build -c release --arch arm64 --arch x86_64 2>/dev/null \
  || swift build -c release
BIN="$(swift build -c release --show-bin-path)/${EXE}"
# bản universal nằm ở đường dẫn khác
[ -f ".build/apple/Products/Release/${EXE}" ] && BIN=".build/apple/Products/Release/${EXE}"

rm -rf "$OUT"
mkdir -p "$OUT/Contents/MacOS" "$OUT/Contents/Resources"
cp "$BIN" "$OUT/Contents/MacOS/${EXE}"
cp Resources/AppIcon.icns "$OUT/Contents/Resources/AppIcon.icns"

cat > "$OUT/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
  <key>CFBundleExecutable</key><string>${EXE}</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>2.0</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF

# ký ad-hoc để Gatekeeper cho chạy trên máy mình
codesign --force --deep --sign - "$OUT"

echo "✅ Xong: $OUT"
echo "   Chạy: open \"$OUT\"   hoặc kéo vào /Applications"
