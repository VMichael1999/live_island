import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

import 'fixtures/html_presets.dart';

void main() {
  final fx = HtmlFixtures.load();
  final now = fx.now;

  String sev(LiveSeverity s) => s.name;

  group('mismos avisos que el panel "Validación" del HTML', () {
    for (final p in fx.presets) {
      test('preset ${p.id}', () {
        final report = LiveIsland.check(
          // Sin androidSmallIcon: así el HTML avisa de la silueta.
          fx.layoutOf(p, withSmallIcon: false),
          fx.stateOf(p),
          now: now,
          androidPromotable: p.androidOk,
        );
        final got = [
          for (final c in report.items) (sev: sev(c.severity), text: c.message),
        ];
        expect(got, fx.checks[p.id]);
      });
    }

    test('el aviso de silueta desaparece al pasar androidSmallIcon', () {
      final taxi = fx.presets.firstWhere((p) => p.id == 'taxi');
      final withIcon = LiveIsland.check(
        fx.layoutOf(taxi),
        fx.stateOf(taxi),
        now: now,
      );
      final without = LiveIsland.check(
        fx.layoutOf(taxi, withSmallIcon: false),
        fx.stateOf(taxi),
        now: now,
      );
      expect(without.byCode('androidSmallIcon'), isNotNull);
      expect(withIcon.byCode('androidSmallIcon'), isNull);
    });
  });

  group('reglas individuales', () {
    LiveLayout base({
      LiveNode? compactTrailing,
      LiveAndroid? android,
      LiveExpanded? expanded,
      LiveVisual? appLogo,
      LiveVisual? androidSmallIcon,
    }) => LiveLayout(
      theme: const LiveTheme(accent: Color(0xFF1F6FEB)),
      compactTrailing: compactTrailing,
      android: android,
      expanded: expanded,
      appLogo: appLogo,
      androidSmallIcon: androidSmallIcon,
    );

    LiveCheck? code(LiveReport r, String c) => r.byCode(c);

    test('estado que pasa de 4 096 bytes es un error', () {
      final r = LiveIsland.check(base(), {'x': 'a' * 5000}, now: now);
      expect(code(r, 'statePayload')!.severity, LiveSeverity.bad);
      expect(r.hasErrors, isTrue);
    });

    test('dato destacado de más de 7 caracteres avisa', () {
      final r = LiveIsland.check(base(compactTrailing: LiveText(bind('d'))), {
        'd': '12345678',
      }, now: now);
      expect(code(r, 'highlightLength')!.severity, LiveSeverity.warn);
      expect(code(r, 'highlightLength')!.message, contains('8 caracteres'));
    });

    test('cuenta la longitud en caracteres, no en bytes', () {
      final r = LiveIsland.check(base(compactTrailing: LiveText(bind('d'))), {
        'd': 'ñññññññ',
      }, now: now);
      expect(code(r, 'highlightLength')!.severity, LiveSeverity.ok);
    });

    test('una cuenta regresiva en el dato destacado se mide como mm:ss', () {
      final r = LiveIsland.check(
        base(compactTrailing: LiveText.countdown(bind('t'))),
        {'t': now.add(const Duration(hours: 1, minutes: 30)).toIso8601String()},
        now: now,
      );
      // "1:30:00" tiene 7 caracteres: todavía cabe.
      expect(code(r, 'highlightLength')!.severity, LiveSeverity.ok);
    });

    test('un dato destacado que no es texto no genera aviso', () {
      final r = LiveIsland.check(
        base(compactTrailing: const LiveIcon.symbol('car.fill')),
        const {},
        now: now,
      );
      expect(code(r, 'highlightLength'), isNull);
    });

    group('chip de Android', () {
      LiveReport chip(LiveChip c, [Map<String, Object?> s = const {}]) =>
          LiveIsland.check(
            base(
              android: LiveAndroid(title: const LiveText.literal('T'), chip: c),
            ),
            s,
            now: now,
          );

      test('7 caracteres o menos se ve completo', () {
        final r = chip(const LiveChip.text('B-027'));
        expect(code(r, 'chip')!.severity, LiveSeverity.ok);
        expect(
          code(r, 'chip')!.message,
          'Chip de Android completo (5 caracteres).',
        );
      });

      test('de 8 a 12 se recorta', () {
        final r = chip(
          const LiveChip.text(
            'Llega ya mismo'.length > 12 ? 'Llegando ya' : 'x',
          ),
        );
        expect(code(r, 'chip')!.severity, LiveSeverity.warn);
        expect(code(r, 'chip')!.message, contains('recortado'));
        expect(code(r, 'chip')!.message, contains('11 caracteres'));
      });

      test('más de 12 caracteres queda solo el ícono', () {
        final r = chip(const LiveChip.text('Texto demasiado largo'));
        expect(
          code(r, 'chip')!.message,
          'Chip de Android solo con ícono: el texto es demasiado largo.',
        );
      });

      test('chip de solo ícono', () {
        final r = chip(const LiveChip.icon());
        expect(code(r, 'chip')!.message, 'Chip de Android solo con ícono.');
      });

      test('la cuenta regresiva muestra minutos, mínimo 1', () {
        final r = chip(LiveChip.countdown(bind('t')), {
          't': now.add(const Duration(seconds: 20)).toIso8601String(),
        });
        expect(
          code(r, 'chip')!.message,
          'Chip de Android completo (5 caracteres).',
        );
      });

      test('sin chip no hay aviso', () {
        final r = LiveIsland.check(
          base(android: const LiveAndroid(title: LiveText.literal('T'))),
          const {},
          now: now,
        );
        expect(code(r, 'chip'), isNull);
      });
    });

    group('promoción a Live Update', () {
      LiveReport promo({
        LiveAndroid? android,
        bool promotable = true,
        Map<String, Object?> s = const {},
      }) => LiveIsland.check(
        base(android: android),
        s,
        now: now,
        androidPromotable: promotable,
      );

      test('con título y sin colorear se promueve', () {
        final r = promo(
          android: LiveAndroid(title: bind('t')),
          s: {'t': 'Hola'},
        );
        expect(code(r, 'androidPromotion')!.severity, LiveSeverity.ok);
      });

      test('colorized impide la promoción', () {
        final r = promo(
          android: const LiveAndroid(
            title: LiveText.literal('T'),
            colorized: true,
          ),
        );
        expect(code(r, 'androidPromotion')!.severity, LiveSeverity.bad);
        expect(
          code(r, 'androidPromotion')!.message,
          contains('setColorized(true)'),
        );
      });

      test('sin título impide la promoción', () {
        expect(
          code(
            promo(android: const LiveAndroid()),
            'androidPromotion',
          )!.message,
          contains('título'),
        );
        expect(code(promo(), 'androidPromotion')!.severity, LiveSeverity.bad);
        final empty = promo(
          android: LiveAndroid(title: bind('t')),
          s: {'t': ''},
        );
        expect(code(empty, 'androidPromotion')!.severity, LiveSeverity.bad);
      });

      test('un caso no promovible se marca antes que lo demás', () {
        final r = promo(
          android: const LiveAndroid(
            title: LiveText.literal('T'),
            colorized: true,
          ),
          promotable: false,
        );
        expect(
          code(r, 'androidPromotion')!.message,
          contains('no lo inició el usuario'),
        );
      });
    });

    group('progreso', () {
      LiveLayout withBottom(LiveNode node, {LiveAndroid? android}) => base(
        expanded: LiveExpanded(bottom: LiveColumn([node])),
        android: android ?? const LiveAndroid(title: LiveText.literal('T')),
      );

      test('el anillo avisa que en Android es una barra', () {
        final r = LiveIsland.check(
          withBottom(LiveProgress.ring(value: bind('p'))),
          const {'p': 0.5},
          now: now,
        );
        expect(code(r, 'ringOnAndroid')!.severity, LiveSeverity.warn);
      });

      test(
        'si Android define su propia barra, el anillo de la isla no avisa',
        () {
          final r = LiveIsland.check(
            withBottom(
              LiveProgress.ring(value: bind('p')),
              android: LiveAndroid(
                title: const LiveText.literal('T'),
                progress: LiveProgress.bar(value: bind('p')),
              ),
            ),
            const {'p': 0.5},
            now: now,
          );
          expect(code(r, 'ringOnAndroid'), isNull);
        },
      );

      test('una barra no avisa', () {
        final r = LiveIsland.check(
          withBottom(LiveProgress.bar(value: bind('p'))),
          const {'p': 0.5},
          now: now,
        );
        expect(code(r, 'ringOnAndroid'), isNull);
      });

      test('etapas con menos de dos etiquetas avisan', () {
        final r = LiveIsland.check(
          withBottom(LiveSegments(value: bind('p'), labels: ['solo una'])),
          const {'p': 0.5},
          now: now,
        );
        expect(code(r, 'segmentsFewStages')!.severity, LiveSeverity.warn);
      });
    });

    group('imágenes', () {
      test('un logo propio sin silueta de Android avisa', () {
        final r = LiveIsland.check(
          base(appLogo: LiveImage.asset('assets/logo.png')),
          const {},
          now: now,
        );
        expect(code(r, 'androidSmallIcon')!.severity, LiveSeverity.warn);
      });

      test('un ícono del sistema como logo no avisa', () {
        final r = LiveIsland.check(
          base(appLogo: const LiveIcon.symbol('car.fill')),
          const {},
          now: now,
        );
        expect(code(r, 'androidSmallIcon'), isNull);
      });

      test('informa el peso de una imagen en memoria', () {
        final img = LiveImage.memory(Uint8List(3 * 1024), fit: LiveFit.cover);
        final r = LiveIsland.check(
          base(appLogo: img, androidSmallIcon: img),
          const {},
          now: now,
        );
        expect(
          code(r, 'imageSize')!.message,
          'Logo de la app: 3 KB, se reduce a 120 × 120 px antes de copiarse al App Group (iOS). Proporción respetada con fit “cover”.',
        );
      });

      test('si no se conoce el peso, igual informa el tamaño final', () {
        final img = LiveImage.asset('assets/logo.png');
        final r = LiveIsland.check(
          base(appLogo: img, androidSmallIcon: img),
          const {},
          now: now,
        );
        expect(
          code(r, 'imageSize')!.message,
          'Logo de la app: se reduce a 120 × 120 px antes de copiarse al App Group (iOS). Proporción respetada con fit “contain”.',
        );
      });

      test('distingue ícono principal, foto del avatar y tracker', () {
        final layout = LiveLayout(
          theme: const LiveTheme(accent: Color(0xFF1F6FEB)),
          compactLeading: LiveImage.asset('assets/icono.png'),
          expanded: LiveExpanded(
            leading: LiveImage.asset(
              'assets/foto.jpg',
              shape: LiveShape.circle,
            ),
            bottom: LiveProgress.bar(
              value: bind('p'),
              tracker: LiveTracker(
                LiveImage.asset('assets/auto.png'),
                background: LiveTrackerBackground.none,
              ),
            ),
          ),
        );
        final labels =
            LiveIsland.check(layout, const {'p': 0.1}, now: now).items
                .where((c) => c.code == 'imageSize')
                .map((c) => c.message.split(':').first)
                .toList();
        expect(labels, [
          'Imagen del ícono principal',
          'Foto del avatar',
          'Imagen que avanza en la barra',
        ]);
      });
    });

    test('el informe se imprime una línea por aviso', () {
      final r = LiveIsland.check(base(), const {}, now: now);
      expect(r.toString(), startsWith('[ok] Estado por actualización'));
      expect(r.hasWarnings, isFalse);
    });
  });
}
