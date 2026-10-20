#!/bin/sh
# La fuente del renderer de iOS es ios/LiveIslandExtension (lo que copia
# `dart run live_island_kit:setup`). El ejemplo trae una copia que su proyecto de
# Xcode referencia: este script la deja igual a la fuente.
#
#   tool/sincronizar_swift.sh
set -e
cd "$(dirname "$0")/.."
for dir in Renderer Widget; do
  rsync -a --delete "ios/LiveIslandExtension/$dir/" "example/ios/LiveIslandExtension/$dir/"
done
echo "Renderer y Widget del ejemplo sincronizados con ios/LiveIslandExtension."
