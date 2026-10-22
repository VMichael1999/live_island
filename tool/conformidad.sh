#!/bin/sh
# Corre los casos de doc/contract/conformance.json en las tres plataformas.
#
#   tool/conformidad.sh
#
# Swift necesita un simulador de iPhone encendido; Kotlin, JDK 21 (JAVA_HOME).
set -e
cd "$(dirname "$0")/.."
echo "== Dart =="
flutter test test/conformidad_test.dart test/textos_resueltos_test.dart
echo "== Kotlin =="
(cd example/android && ./gradlew :live_island_kit:testDebugUnitTest --tests '*LiveConformanceTest*' --tests '*LiveResolvedTextsTest*' -q)
echo "Kotlin: casos de conformidad, todos bien."
echo "== Swift =="
tool/conformidad_swift.sh
