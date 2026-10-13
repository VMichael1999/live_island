import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

void main() {
  group('LiveButton.reply', () {
    test('lleva el texto de ayuda en `input` y no tiene acción', () {
      final b = LiveButton.reply(
        id: 'responder',
        label: 'Responder',
        hint: 'Escribe tu mensaje',
      );
      expect(b.replyHint, 'Escribe tu mensaje');
      expect(b.toJson(), {
        't': 'button',
        'id': 'responder',
        'label': 'Responder',
        'input': {'hint': 'Escribe tu mensaje'},
      });
    });

    test('sin hint usa «Responder»', () {
      expect(LiveButton.reply(id: 'r', label: 'R').toJson()['input'], {
        'hint': 'Responder',
      });
    });

    test('un botón normal no lleva `input`', () {
      expect(
        LiveButton(id: 'a', label: 'A').toJson().containsKey('input'),
        isFalse,
      );
      expect(LiveButton(id: 'a', label: 'A').replyHint, isNull);
    });

    test('ida y vuelta por JSON', () {
      final b = LiveButton.reply(id: 'responder', label: 'R', hint: 'Mensaje');
      final back = LiveButton.fromJson(b.toJson());
      expect(back.replyHint, 'Mensaje');
      expect(back.toJson(), b.toJson());
    });

    test('valida el id como cualquier botón', () {
      expect(
        () => LiveButton.reply(id: 'Mal Id', label: 'x'),
        throwsArgumentError,
      );
    });

    test('el diseño con una respuesta pasa check() sin errores', () {
      final layout = LiveLayout(
        theme: const LiveTheme(accent: Color(0xFF1F6FEB)),
        compactLeading: const LiveText.literal('c'),
        android: const LiveAndroid(title: LiveText.literal('Viaje')),
        expanded: LiveExpanded(
          bottom: LiveRow([
            LiveButton.reply(id: 'responder', label: 'Responder'),
            LiveButton(id: 'llamar', label: 'Llamar'),
          ]),
        ),
      );
      final r = LiveIsland.check(layout, const {});
      expect(r.items.where((c) => c.severity == LiveSeverity.bad), isEmpty);
      expect(LiveLayout.fromJson(layout.toJson()).toJson(), layout.toJson());
    });
  });
}
