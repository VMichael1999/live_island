import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La fuente del renderer de iOS es `ios/LiveIslandExtension`; el ejemplo trae
/// una copia. Si esta prueba falla, ejecuta `tool/sincronizar_swift.sh`.
void main() {
  for (final dir in ['Renderer', 'Widget']) {
    test('el $dir de Swift del ejemplo es igual al de la fuente', () {
      final fuente = Directory('ios/LiveIslandExtension/$dir');
      final copia = Directory('example/ios/LiveIslandExtension/$dir');
      final nombres = fuente.listSync().whereType<File>().map(
        (f) => f.uri.pathSegments.last,
      );
      expect(nombres, isNotEmpty);
      for (final n in nombres) {
        expect(
          File('${copia.path}/$n').readAsStringSync(),
          File('${fuente.path}/$n').readAsStringSync(),
          reason: '$dir/$n se desvió: ejecuta tool/sincronizar_swift.sh',
        );
      }
    });
  }
}
