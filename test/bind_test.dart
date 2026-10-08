import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

void main() {
  test('bind crea enlaces comparables', () {
    expect(bind('a'), bind('a'));
    expect(bind('a'), isNot(bind('b')));
    expect(bind('a').toString(), "bind('a')");
  });

  group('LiveCondition', () {
    final state = <String, Object?>{
      'etapa': 2,
      'progreso': 0.5,
      'ok': true,
      'nombre': '',
    };

    test('equals y notEquals', () {
      expect(bind('etapa').equals(2).evaluate(state), isTrue);
      expect(bind('etapa').equals(2.0).evaluate(state), isTrue);
      expect(bind('etapa').equals(3).evaluate(state), isFalse);
      expect(bind('etapa').notEquals(3).evaluate(state), isTrue);
    });

    test('comparaciones numéricas', () {
      expect(bind('progreso').greaterThan(0.4).evaluate(state), isTrue);
      expect(bind('progreso').greaterOrEqual(0.5).evaluate(state), isTrue);
      expect(bind('progreso').lessThan(0.5).evaluate(state), isFalse);
      expect(bind('progreso').lessOrEqual(0.5).evaluate(state), isTrue);
      expect(bind('nombre').greaterThan(1).evaluate(state), isFalse);
    });

    test('isTrue considera vacío, cero y nulo como falso', () {
      expect(bind('ok').isTrue.evaluate(state), isTrue);
      expect(bind('nombre').isTrue.evaluate(state), isFalse);
      expect(bind('no_existe').isTrue.evaluate(state), isFalse);
    });

    test('se serializa como bind + un operador', () {
      expect(bind('etapa').equals(2).toJson(), {'bind': 'etapa', 'eq': 2});
      expect(LiveCondition.fromJson({'bind': 'x', 'lte': 3}).op, 'lte');
      expect(
        () => LiveCondition.fromJson({'bind': 'x'}),
        throwsFormatException,
      );
      expect(
        () => LiveCondition.fromJson({'bind': 'x', 'eq': 1, 'gt': 0}),
        throwsFormatException,
      );
    });
  });

  test('formatTemplate sustituye campos y deja vacíos los que faltan', () {
    expect(formatTemplate('{a} · {b}', {'a': 'x', 'b': 2}), 'x · 2');
    expect(formatTemplate('{a}{z}', {'a': 'x'}), 'x');
  });
}
