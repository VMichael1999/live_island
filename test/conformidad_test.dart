import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/live_island_kit.dart';
import 'package:live_island_kit/src/core/bind.dart';
import 'package:live_island_kit/src/core/countdown.dart';

/// Los mismos casos que ejecutan Swift y Kotlin (`doc/contract/conformance.json`):
/// si una plataforma resuelve algo distinto, falla su prueba.
void main() {
  final casos =
      jsonDecode(File('doc/contract/conformance.json').readAsStringSync())
          as Map<String, Object?>;
  List<Map<String, Object?>> lista(String k) => [
    for (final c in casos[k]! as List) (c as Map).cast<String, Object?>(),
  ];

  group('conformidad · plantillas {campo}', () {
    for (final c in lista('format')) {
      test(c['nombre']! as String, () {
        final state = (c['state']! as Map).cast<String, Object?>();
        expect(formatTemplate(c['fmt']! as String, state), c['expect']);
      });
    }
  });

  group('conformidad · condiciones', () {
    for (final c in lista('condition')) {
      test(c['nombre']! as String, () {
        final state = (c['state']! as Map).cast<String, Object?>();
        final cond = LiveCondition.fromJson(
          (c['cond']! as Map).cast<String, Object?>(),
        );
        expect(cond.evaluate(state), c['expect']);
      });
    }
  });

  group('conformidad · cuenta regresiva', () {
    for (final c in lista('countdown')) {
      test('${c['segundos']} s', () {
        expect(formatCountdown(c['segundos']! as int), c['expect']);
      });
    }
  });
}
