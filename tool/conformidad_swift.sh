#!/bin/sh
# Corre doc/contract/conformance.json con la lógica de iOS (LiveCtx.format y
# LiveCtx.evaluate). Compila el modelo del renderer con un programa de prueba para
# el simulador de iPhone y lo ejecuta en un simulador encendido.
#
#   tool/conformidad_swift.sh
set -e
cd "$(dirname "$0")/.."
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=$(mktemp -d)
EXT=ios/LiveIslandExtension/Renderer
SHARED=ios/live_island_kit/Sources/live_island_kit/Shared
cp tool/conformidad/conformidad_swift.swift "$OUT/main.swift"
xcrun swiftc -sdk "$SDK" -target arm64-apple-ios16.1-simulator -o "$OUT/conformidad" \
  "$EXT/LiveLayoutModel.swift" "$EXT/LiveStyle.swift" "$SHARED/LiveIslandAttributes.swift" "$SHARED/LiveStorage.swift" "$OUT/main.swift" 2>&1 | grep -E "error" || true
cp doc/contract/conformance.json "$OUT/conformance.json"
xcrun simctl spawn booted "$OUT/conformidad" "$OUT/conformance.json"
