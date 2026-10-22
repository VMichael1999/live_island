#!/bin/sh
# Corre las pruebas de integración (example/integration_test) contra la
# plataforma real: ActivityKit en un simulador de iPhone o las notificaciones de
# un emulador de Android. Necesitan el dispositivo ya encendido.
#
#   tool/integracion.sh <id del dispositivo>     (ver `flutter devices`)
#
# En Android el emulador debe tener el permiso de notificaciones:
#   adb shell pm grant com.vmichael1999.live_island_example android.permission.POST_NOTIFICATIONS
# y JDK 21 en JAVA_HOME.
set -e
[ -n "$1" ] || { sed -n '2,11p' "$0"; exit 64; }
cd "$(dirname "$0")/../example"
flutter test integration_test -d "$1"
