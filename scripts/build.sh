#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
SDK=$(xcrun --sdk iphoneos --show-sdk-path)
xcrun --sdk iphoneos clang -arch arm64 -isysroot "$SDK" \
  -miphoneos-version-min=15.0 -fobjc-arc -fblocks -O2 -Wall -Wextra -Werror \
  -dynamiclib src/DGPolicy.m src/DGHook.m src/DGGemini.m src/DGTranslation.m src/DGGeminiUI.m src/DouyinGuest.m \
  -framework Foundation -framework UIKit -framework CoreGraphics \
  -Wl,-install_name,@rpath/DouyinGuest.dylib -o build/DouyinGuest.dylib
codesign --force --sign - --timestamp=none build/DouyinGuest.dylib
codesign --verify --strict build/DouyinGuest.dylib
lipo -info build/DouyinGuest.dylib
otool -L build/DouyinGuest.dylib
shasum -a 256 build/DouyinGuest.dylib > build/SHA256SUMS
