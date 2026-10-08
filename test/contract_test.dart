import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';
import 'package:live_island/live_island.dart';

import 'fixtures/html_presets.dart';

JsonSchema _schema(String name) => JsonSchema.create(
  File('docs/contract/$name.schema.json').readAsStringSync(),
  schemaVersion: SchemaVersion.draft2020_12,
);

Map<String, Object?> _json(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, Object?>();

void main() {
  final layoutSchema = _schema('layout');
  final stateSchema = _schema('state');
  final fx = HtmlFixtures.load();

  group('lo que escribe el paquete cumple el contrato', () {
    for (final p in fx.presets) {
      test('layout y estado del preset ${p.id}', () {
        final layout = jsonDecode(jsonEncode(fx.layoutOf(p).toJson()));
        final result = layoutSchema.validate(layout);
        expect(result.isValid, isTrue, reason: '${result.errors}');
        final state = jsonDecode(
          jsonEncode(LiveState.normalize(fx.stateOf(p))),
        );
        final sr = stateSchema.validate(state);
        expect(sr.isValid, isTrue, reason: '${sr.errors}');
      });
    }

    test('LiveState.normalize convierte fechas a ISO 8601 UTC', () {
      final n = LiveState.normalize({
        'llegaA': DateTime.utc(2026, 10, 4, 15, 6),
      });
      expect(n['llegaA'], '2026-10-04T15:06:00.000Z');
    });
  });

  group('ejemplos del contrato', () {
    for (final name in ['taxi', 'score']) {
      test('$name es válido', () {
        expect(
          layoutSchema
              .validate(_json('docs/contract/examples/$name.layout.json'))
              .isValid,
          isTrue,
        );
        expect(
          stateSchema
              .validate(_json('docs/contract/examples/$name.state.json'))
              .isValid,
          isTrue,
        );
      });
    }
  });

  group('lo inválido se rechaza', () {
    Map<String, Object?> taxi() =>
        _json('docs/contract/examples/taxi.layout.json');

    test('color de acento mal escrito', () {
      final j = taxi();
      (j['theme']! as Map)['accent'] = 'azul';
      expect(layoutSchema.validate(j).isValid, isFalse);
    });

    test('tipo de nodo desconocido', () {
      final j = taxi();
      ((j['regions']! as Map)['compactLeading']! as Map)['t'] = 'nope';
      expect(layoutSchema.validate(j).isValid, isFalse);
    });

    test('propiedad inventada', () {
      final j = taxi();
      ((j['regions']! as Map)['compactTrailing']! as Map)['foo'] = 1;
      expect(layoutSchema.validate(j).isValid, isFalse);
    });

    test('estado con objetos anidados o claves inválidas', () {
      expect(
        stateSchema.validate({
          'a': {'b': 1},
        }).isValid,
        isFalse,
      );
      expect(stateSchema.validate({'a b': 1}).isValid, isFalse);
    });
  });

  group('LiveState', () {
    test('rechaza tipos que no viajan', () {
      expect(
        () => LiveState.normalize({
          'a': <int>[1],
        }),
        throwsArgumentError,
      );
      expect(() => LiveState.normalize({'a': double.nan}), throwsArgumentError);
      expect(() => LiveState.normalize({'1a': 1}), throwsArgumentError);
    });

    test('mide los bytes del estado normalizado', () {
      expect(LiveState.byteSize({'a': 'ñ'}), utf8.encode('{"a":"ñ"}').length);
    });
  });
}
