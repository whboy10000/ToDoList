#!/usr/bin/env bash
# ToDOList 一键打包脚本（在 macOS 上运行）
# 产物输出到 releases/ 目录
#  - macOS:  ToDOList-macos.dmg
#  - Android: ToDOList-android.apk
#  - iOS:    ToDOList-ios-unsigned.ipa（未签名，需自行签名后才能安装到真机）
# Windows/Linux 无法在 macOS 上交叉编译，请使用 .github/workflows/build.yml 在 CI 构建。
set -euo pipefail
cd "$(dirname "$0")"

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
OUT=releases
mkdir -p "$OUT"

echo "==> 1/3 macOS"
flutter build macos --release
APP=build/macos/Build/Products/Release/ToDOList.app
hdiutil create -volname ToDOList -srcfolder "$APP" -ov -format UDZO \
  "$OUT/ToDOList-$VERSION-macos.dmg"

echo "==> 2/3 Android"
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk "$OUT/ToDOList-$VERSION-android.apk"

echo "==> 3/3 iOS (未签名)"
flutter build ios --release --no-codesign
APP_DIR=$(find build/ios/iphoneos -name "Runner.app" -maxdepth 1)
rm -rf /tmp/Payload "$OUT/ToDOList-$VERSION-ios-unsigned.ipa"
mkdir -p /tmp/Payload
cp -R "$APP_DIR" /tmp/Payload/
(cd /tmp && zip -qry "$OLDPWD/$OUT/ToDOList-$VERSION-ios-unsigned.ipa" Payload)

echo
echo "打包完成，产物列表："
ls -lh "$OUT"
