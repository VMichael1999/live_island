import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/live_island_kit.dart';
import 'package:live_island_kit/src/core/bind.dart';

import 'fixtures/todos_los_presets.dart';

/// Los textos que cada preset muestra con sus datos de ejemplo, resueltos sobre
/// el JSON del diseño (`doc/contract/resolved_texts.json`). Swift y Kotlin
/// recorren el mismo JSON con su propia lógica (`if`, `{campo}`, `bind`) y deben
/// dar la misma lista: si una plataforma resuelve distinto un diseño real, falla.
///
/// Para regenerar el archivo: `ACTUALIZAR_TEXTOS=1 flutter test test/textos_resueltos_test.dart`.
void main() {
  final archivo = File('doc/contract/resolved_texts.json');

  Object? paraJson(Object? v) => switch (v) {
    DateTime() => v.toUtc().toIso8601String(),
    Map() => {for (final e in v.entries) e.key as String: paraJson(e.value)},
    List() => [for (final e in v) paraJson(e)],
    _ => v,
  };

  // Mismas reglas que SwiftUI y la tarjeta de Android: un `if` elige su rama y
  // el resto del árbol se recorre entero; solo cuentan los nodos `text`.
  void recorrer(Object? n, Map<String, Object?> state, List<String> out) {
    if (n is List) {
      for (final e in n) {
        recorrer(e, state, out);
      }
    } else if (n is Map) {
      final t = n['t'];
      if (t == 'if') {
        final ok = LiveCondition.fromJson(
          (n['when']! as Map).cast<String, Object?>(),
        ).evaluate(state);
        recorrer(ok ? n['then'] : n['else'], state, out);
        return;
      }
      if (t == 'text') {
        if (n['fmt'] is String) {
          out.add(formatTemplate(n['fmt']! as String, state));
        } else if (n['text'] is String) {
          out.add(n['text']! as String);
        } else if (n['bind'] is String) {
          out.add(liveText(state[n['bind']]));
        } else {
          out.add('');
        }
      }
      for (final e in n.entries) {
        if (e.key == 'when') continue;
        recorrer(e.value, state, out);
      }
    }
  }

  List<Map<String, Object?>> calcular() => [
    for (final p in todosLosPresets)
      () {
        final layout =
            jsonDecode(jsonEncode(p.build().toJson())) as Map<String, Object?>;
        final state =
            (paraJson(p.sampleState(now: DateTime.utc(2026, 10, 4, 15)))!
                    as Map)
                .cast<String, Object?>();
        final texts = <String>[];
        recorrer(layout, state, texts);
        texts.sort();
        return <String, Object?>{
          'name': '${p.runtimeType}',
          'layout': layout,
          'state': state,
          'texts': texts,
        };
      }(),
  ];

  test('los textos resueltos del archivo son los que da Dart', () {
    final actual = calcular();
    if (Platform.environment['ACTUALIZAR_TEXTOS'] == '1') {
      archivo.writeAsStringSync(
        '${const JsonEncoder.withIndent(' ').convert({'presets': actual})}\n',
      );
      return;
    }
    final guardado =
        (jsonDecode(archivo.readAsStringSync())
                as Map<String, Object?>)['presets']!
            as List;
    expect(
      [for (final c in guardado) (c as Map)['texts']],
      [for (final c in actual) c['texts']],
      reason: 'regenera con ACTUALIZAR_TEXTOS=1',
    );
    expect(
      [for (final c in guardado) (c as Map)['layout']],
      [for (final c in actual) c['layout']],
      reason: 'el diseño cambió: regenera con ACTUALIZAR_TEXTOS=1',
    );
  });

  test('ningún preset resuelve un texto con una llave sin reemplazar', () {
    for (final c in calcular()) {
      for (final t in (c['texts']! as List).cast<String>()) {
        expect(
          t,
          isNot(matches(RegExp(r'\{[A-Za-z_]'))),
          reason: '${c['name']}',
        );
      }
    }
  });
}
