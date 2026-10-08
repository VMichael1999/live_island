import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

import 'fixtures/html_presets.dart';

Map<String, Object?> _json(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, Object?>();

void main() {
  final fx = HtmlFixtures.load();

  group('ida y vuelta del layout', () {
    for (final p in fx.presets) {
      test('preset ${p.id}', () {
        final layout = fx.layoutOf(p);
        final first = layout.toJson();
        // Pasa por texto, como viaja al dispositivo.
        final parsed = LiveLayout.fromJson(
          (jsonDecode(jsonEncode(first)) as Map).cast<String, Object?>(),
        );
        expect(parsed.toJson(), first);
      });
    }

    test(
      'los ejemplos del contrato se leen y se reescriben de forma estable',
      () {
        for (final name in ['taxi', 'score']) {
          final src = _json('docs/contract/examples/$name.layout.json');
          final once = LiveLayout.fromJson(src);
          final out = once.toJson(
            resolved: {
              for (final e in (src['images'] as Map? ?? {}).entries)
                e.key as String: LiveImageMeta.fromJson(
                  (e.value as Map).cast<String, Object?>(),
                ),
            },
          );
          expect(
            LiveLayout.fromJson(out).toJson(
              resolved: {
                for (final e in (src['images'] as Map? ?? {}).entries)
                  e.key as String: LiveImageMeta.fromJson(
                    (e.value as Map).cast<String, Object?>(),
                  ),
              },
            ),
            out,
          );
          expect(out['images'], src['images']);
          expect(out['android'], src['android']);
          expect((out['regions'] as Map)['lockScreen'], {'same': 'expanded'});
        }
      },
    );
  });

  group('contenido del JSON', () {
    test('el diseño nunca lleva datos, solo enlaces', () {
      final p = fx.presets.firstWhere((p) => p.id == 'taxi');
      final text = jsonEncode(fx.layoutOf(p).toJson());
      expect(text, isNot(contains('Carlos M.')));
      expect(text, isNot(contains('Tu conductor')));
      expect(text, contains('"bind":"titulo"'));
    });

    test('la imagen del tracker conserva su configuración', () {
      final p = fx.presets.firstWhere((p) => p.id == 'taxi');
      final regions = fx.layoutOf(p).toJson()['regions'] as Map;
      final bottom = (regions['expanded'] as Map)['bottom'] as Map;
      final seg = (bottom['c'] as List).first as Map;
      expect(seg['t'], 'segments');
      expect(seg['labels'], ['Asignado', 'En camino', 'Llegó']);
      expect(seg['points'], true);
      final tracker = seg['tracker'] as Map;
      expect(tracker['height'], 24);
      expect(tracker['background'], 'none');
      expect((tracker['visual'] as Map)['t'], 'image');
    });

    test('un ícono usado como tracker se envuelve con su fondo de acento', () {
      final json =
          LiveProgress.bar(
            value: bind('p'),
            tracker: const LiveIcon.symbol('bicycle'),
          ).toJson();
      expect(json['tracker'], {
        'visual': {'t': 'icon', 'sf': 'bicycle'},
        'height': 24,
        'background': 'accentCircle',
      });
    });

    test('las imágenes repetidas se registran una sola vez', () {
      final img = LiveImage.asset('assets/logo.png');
      final layout = LiveLayout(
        theme: const LiveTheme(accent: Color(0xFF1F6FEB)),
        appLogo: img,
        compactLeading: LiveImage.asset(
          'assets/logo.png',
          shape: LiveShape.circle,
        ),
      );
      expect(layout.images, hasLength(1));
      expect((layout.toJson()['images'] as Map).keys, [
        'asset_assets_logo_png',
      ]);
    });

    test('el manifiesto usa las dimensiones resueltas por el plugin', () {
      final img = LiveImage.asset('assets/auto.png', width: 400, height: 180);
      final layout = LiveLayout(
        theme: const LiveTheme(accent: Color(0xFF000000)),
        appLogo: img,
      );
      expect((layout.toJson()['images'] as Map)[img.id], {
        'file': '${img.id}.png',
        'w': 400,
        'h': 180,
      });
      final resolved = layout.toJson(
        resolved: {img.id: const LiveImageMeta(file: 'a.png', w: 216, h: 97)},
      );
      expect((resolved['images'] as Map)[img.id], {
        'file': 'a.png',
        'w': 216,
        'h': 97,
      });
    });

    test('el color se serializa en mayúsculas y con alfa si no es opaco', () {
      expect(
        const LiveTheme(accent: Color(0xFF1F6FEB)).toJson()['accent'],
        '#1F6FEB',
      );
      expect(
        const LiveBox(color: Color(0x801F6FEB)).toJson()['color'],
        '#1F6FEB80',
      );
    });
  });

  group('lectura de JSON', () {
    test('rechaza una versión de contrato distinta', () {
      final src = _json('docs/contract/examples/score.layout.json')..['v'] = 2;
      expect(() => LiveLayout.fromJson(src), throwsFormatException);
    });

    test('rechaza un tipo de nodo desconocido', () {
      expect(() => LiveNode.fromJson({'t': 'nope'}), throwsFormatException);
    });

    test('los botones exigen un id en minúsculas', () {
      expect(
        () => LiveButton(id: 'Llamar', label: 'Llamar'),
        throwsArgumentError,
      );
      expect(
        () => LiveButton(id: 'ver codigo', label: 'x'),
        throwsArgumentError,
      );
      expect(LiveButton(id: 'ver_codigo', label: 'x').id, 'ver_codigo');
    });
  });

  group('nodos individuales', () {
    LiveNode again(LiveNode n) => LiveNode.fromJson(
      (jsonDecode(jsonEncode(n.toJson())) as Map).cast<String, Object?>(),
    );

    test('texto: enlazado, literal, plantilla y contadores', () {
      final nodes = <LiveNode>[
        LiveText(bind('a'), size: 22, weight: 700, accent: true, lines: 2),
        const LiveText.literal('Hola', muted: true),
        const LiveText.format('{a} · {b}', align: LiveAlign.end),
        LiveText.countdown(bind('t'), tabular: true),
        LiveText.stopwatch(bind('t')),
        LiveText.relative(bind('t'), color: const Color(0xFFFF0000)),
      ];
      for (final n in nodes) {
        expect(again(n).toJson(), n.toJson());
      }
      expect(nodes.map((n) => n.type), [
        'text',
        'text',
        'text',
        'countdown',
        'stopwatch',
        'relative',
      ]);
    });

    test('LiveText.from cambia solo el estilo', () {
      final base = LiveText.countdown(bind('llegaA'));
      final big = LiveText.from(base, size: 22, weight: 700, accent: true);
      expect(big.toJson(), {
        't': 'countdown',
        'bind': 'llegaA',
        'size': 22,
        'w': 700,
        'accent': true,
      });
      expect(base.toJson(), {'t': 'countdown', 'bind': 'llegaA'});
    });

    test('estructura: row, col, stack, spacer, padding, box e if', () {
      final tree = LiveColumn(
        [
          LiveRow(
            [const LiveSpacer(size: 8), LiveText(bind('a'))],
            gap: 4,
            align: LiveAlign.center,
          ),
          LiveStack([LiveText(bind('b'))]),
          const LivePadding(LiveSpacer(), horizontal: 8, top: 2),
          const LiveBox(size: 46, radius: 14, tint: 0.22),
          LiveIf(
            bind('etapa').equals(2),
            then: LiveText(bind('x')),
            otherwise: const LiveText.literal('-'),
          ),
        ],
        gap: 6,
        align: LiveAlign.end,
      );
      expect(again(tree).toJson(), tree.toJson());
    });

    test('botones, toggle y acciones', () {
      final nodes = <LiveNode>[
        LiveButton(
          id: 'llamar',
          label: 'Llamar',
          icon: const LiveIcon.symbol('phone.fill'),
          action: const LiveAction.call('+51999'),
        ),
        LiveButton(
          id: 'ver',
          label: 'Ver',
          action: const LiveAction.deepLink('miapp://x'),
        ),
        LiveToggle(id: 'pausa', value: bind('pausado'), label: 'Pausa'),
        LiveMetric(value: bind('kw'), unit: 'kW', label: 'Potencia'),
        LiveProgress.ring(
          value: bind('p'),
          child: const LiveIcon.symbol('timer'),
          size: 40,
        ),
        LiveAvatar.bound(bind('iniciales')),
        const LiveAvatar('CM', size: 46),
      ];
      for (final n in nodes) {
        expect(again(n).toJson(), n.toJson());
      }
    });
  });
}
