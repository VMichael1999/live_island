import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';
import 'package:live_island/live_island.dart';
import 'package:live_island/src/platform/image_loader.dart'
    show androidIconPaths;

import 'fixtures/html_presets.dart';

/// El preset de cada caso de la galería. El Taxi lleva las mismas imágenes que
/// usa el HTML para que el diseño sea idéntico.
LivePreset presetFor(String id) => switch (id) {
  'taxi' => TripPreset(
    appLogo: LiveImage.asset(
      'assets/live/logo.png',
      fit: LiveFit.cover,
      byteSize: 1024,
    ),
    tracker: LiveTracker(
      LiveImage.asset('assets/live/auto.png', byteSize: 1024),
      height: 24,
      background: LiveTrackerBackground.none,
    ),
  ),
  'delivery' => const DeliveryPreset(),
  'courier' => const CourierPreset(),
  'pickup' => const PickupPreset(),
  'queue' => const QueuePreset(),
  'flight' => const FlightPreset(),
  'parking' => const ParkingPreset(),
  'ev' => const EvChargingPreset(),
  'workout' => const WorkoutPreset(),
  'cooking' => const CookingTimerPreset(),
  'upload' => const UploadPreset(),
  'tech' => const TechnicianPreset(),
  'transit' => const TransitPreset(),
  'clinic' => const WaitingRoomPreset(),
  'score' => const ScorePreset(),
  _ => throw ArgumentError(id),
};

String canon(Object? json) => jsonEncode(json);

void main() {
  final fx = HtmlFixtures.load();

  group('cada preset coincide con su tarjeta de la galería del HTML', () {
    for (final p in fx.presets) {
      test(p.id, () {
        final preset = presetFor(p.id);
        // Mismo diseño que el "Código Dart generado" del HTML.
        expect(
          canon(preset.build().toJson()),
          canon(fx.layoutOf(p, withSmallIcon: false).toJson()),
        );
        expect(preset.androidPromotable, p.androidOk);
        expect(preset.appName, p.app);
      });

      test('${p.id}: datos de ejemplo', () {
        final got = LiveState.normalize(
          presetFor(p.id).sampleState(now: fx.now),
        );
        final want = Map<String, Object?>.of(LiveState.normalize(fx.stateOf(p)))
          ..remove('etapa'); // el diseño no usa `etapa`
        expect(got, want);
      });

      test('${p.id}: check() da los mismos avisos que el HTML', () {
        final preset = presetFor(p.id);
        final report = LiveIsland.check(
          preset.build(),
          preset.sampleState(now: fx.now),
          now: fx.now,
          androidPromotable: preset.androidPromotable,
        );
        final got = [
          for (final c in report.items.skip(1))
            (sev: c.severity.name, text: c.message),
        ];
        final want =
            fx.checks[p.id]!
                .skip(1)
                .toList(); // la primera fila es el peso del estado
        expect(got, want);
      });
    }
  });

  group('con sus valores por defecto', () {
    final schema = JsonSchema.create(
      File('docs/contract/layout.schema.json').readAsStringSync(),
      schemaVersion: SchemaVersion.draft2020_12,
    );
    final all = <String, LivePreset>{
      'trip': const TripPreset(),
      'delivery': const DeliveryPreset(),
      'courier': const CourierPreset(),
      'pickup': const PickupPreset(),
      'queue': const QueuePreset(),
      'flight': const FlightPreset(),
      'parking': const ParkingPreset(),
      'ev': const EvChargingPreset(),
      'workout': const WorkoutPreset(),
      'cooking': const CookingTimerPreset(),
      'upload': const UploadPreset(),
      'technician': const TechnicianPreset(),
      'transit': const TransitPreset(),
      'waiting': const WaitingRoomPreset(),
      'score': const ScorePreset(),
    };

    for (final e in all.entries) {
      test('${e.key} cumple el contrato JSON', () {
        final json = jsonDecode(jsonEncode(e.value.build().toJson()));
        final r = schema.validate(json);
        expect(r.isValid, isTrue, reason: '${r.errors}');
      });

      test('${e.key}: sus íconos de Android existen en el paquete', () {
        final layout = e.value.build();
        for (final path in androidIconPaths(layout)) {
          final file = path.replaceFirst('packages/live_island/', '');
          expect(File(file).existsSync(), isTrue, reason: 'falta $file');
        }
        for (final img in layout.images) {
          expect(img.key, livePresetCarAsset);
        }
      });

      test('${e.key}: no tiene errores de validación', () {
        final report = LiveIsland.check(
          e.value.build(),
          e.value.sampleState(),
          androidPromotable: e.value.androidPromotable,
        );
        // El único aviso esperado de los presets completos es el de Android (score).
        expect(report.hasErrors, e.value.androidPromotable ? isFalse : isTrue);
      });
    }

    test('la imagen del auto del Taxi existe', () {
      expect(File('assets/presets/car.png').existsSync(), isTrue);
    });
  });

  group('parámetros', () {
    test('el acento cambia el tema y el chip del diseño', () {
      final l = const TripPreset(accent: Color(0xFFD81B60)).build();
      expect(l.theme.accent, const Color(0xFFD81B60));
    });

    test('los botones se reemplazan', () {
      final l =
          TripPreset(
            buttons: [LiveButton(id: 'cancelar', label: 'Cancelar')],
          ).build();
      final ids = [
        for (final n in l.allNodes)
          if (n is LiveButton) n.id,
      ];
      expect(ids, ['cancelar']);
    });

    test('las etapas y los puntos se reemplazan', () {
      final l =
          const DeliveryPreset(
            stages: ['Pedido', 'Cocina', 'Camino', 'Listo'],
            showPoints: false,
          ).build();
      final seg = l.allNodes.whereType<LiveSegments>().single;
      expect(seg.labels, ['Pedido', 'Cocina', 'Camino', 'Listo']);
      expect(seg.points, isFalse);
    });

    test('el fondo de la tarjeta de bloqueo y el avatar', () {
      final l =
          const TechnicianPreset(
            avatarText: 'AB',
            lockBackground: LiveBackground.accent,
          ).build();
      expect(l.theme.background, LiveBackground.accent);
      expect(l.expanded!.leading, isA<LiveAvatar>());
      expect((l.expanded!.leading! as LiveAvatar).text, 'AB');
    });

    test('un logo propio llega a la tarjeta de bloqueo', () {
      final logo = LiveImage.asset('assets/logo.png', fit: LiveFit.cover);
      final l = TripPreset(appLogo: logo).build();
      expect(l.appLogo, same(logo));
      // Sin logo se usa el ícono principal.
      expect(const TripPreset().build().appLogo, isA<LiveIcon>());
    });

    test('el estado de ejemplo se puede probar con otra hora', () {
      final t = DateTime.utc(2026, 1, 1, 10);
      final s = const ParkingPreset().sampleState(now: t);
      expect(s['llegaA'], DateTime.utc(2026, 1, 1, 10, 45));
      expect(const ScorePreset().sampleState()['destacado'], "78'");
    });
  });

  group('la barra es editable', () {
    LiveSegments seg(LivePreset p) =>
        p.build().allNodes.whereType<LiveSegments>().single;

    test(
      'por defecto muestra etiquetas, puntos, ícono que avanza y marcador final',
      () {
        final s = seg(const DeliveryPreset());
        expect(s.showLabels, isTrue);
        expect(s.points, isTrue);
        expect(s.tracker, isNotNull);
        expect(s.endIcon, isNotNull);
        expect(s.style, isNull);
      },
    );

    test('cada parte se puede quitar por separado', () {
      final s = seg(
        const DeliveryPreset(
          showLabels: false,
          showPoints: false,
          showTracker: false,
          showEndIcon: false,
        ),
      );
      expect(s.showLabels, isFalse);
      expect(s.points, isFalse);
      expect(s.tracker, isNull);
      expect(s.endIcon, isNull);
      // La barra sigue ahí, con sus tramos.
      expect(s.labels, hasLength(4));
    });

    test('el estilo llega a la barra y se escribe en el JSON', () {
      const style = LiveProgressStyle(
        height: 12,
        color: Color(0xFFC62828),
        gap: 2,
        pointSize: 14,
      );
      final p = const TripPreset(progressStyle: style);
      expect(seg(p).style, style);
      expect(canon(p.build().toJson()), contains('"h":12'));
      expect(canon(p.build().toJson()), contains('"color":"#C62828"'));
    });

    test('también en las barras sin etapas y en los anillos', () {
      const style = LiveProgressStyle(height: 9, trackColor: Color(0xFF111111));
      final bar =
          const QueuePreset(
            progressStyle: style,
          ).build().allNodes.whereType<LiveProgress>().single;
      expect(bar.style, style);
      final ring =
          const ParkingPreset(progressStyle: style)
              .build()
              .allNodes
              .whereType<LiveProgress>()
              .where((n) => n.isRing)
              .toList();
      expect(ring, isNotEmpty);
      expect(ring.any((r) => r.style == style), isTrue);
    });

    test('los presets sin barra no tienen estas opciones', () {
      expect(
        const ScorePreset().build().allNodes.whereType<LiveProgress>(),
        isEmpty,
      );
    });
  });

  group('override', () {
    test('reemplaza una región completa y deja el resto', () {
      final base = const TripPreset().build();
      final l = const TripPreset().override(
        compactTrailing: const LiveText.literal('ya'),
      );
      expect((l.compactTrailing! as LiveText).literal, 'ya');
      expect(
        canon(l.compactLeading!.toJson()),
        canon(base.compactLeading!.toJson()),
      );
      expect(canon(l.expanded!.toJson()), canon(base.expanded!.toJson()));
      expect(canon(l.android!.toJson()), canon(base.android!.toJson()));
    });

    test('reemplaza una sola zona de la isla expandida', () {
      final base = const ParkingPreset().build();
      final l = const ParkingPreset().override(
        expandedCenter: const LiveText.literal('Hola'),
      );
      expect((l.expanded!.center! as LiveText).literal, 'Hola');
      expect(
        canon(l.expanded!.trailing!.toJson()),
        canon(base.expanded!.trailing!.toJson()),
      );
      expect(
        canon(l.expanded!.bottom!.toJson()),
        canon(base.expanded!.bottom!.toJson()),
      );
    });

    test('puede cambiar el bloque de Android y el tema', () {
      final l = const TripPreset().override(
        android: const LiveAndroid(title: LiveBind('titulo'), colorized: true),
        theme: const LiveTheme(accent: Color(0xFF000000)),
      );
      expect(l.android!.colorized, isTrue);
      expect(l.theme.accent, const Color(0xFF000000));
    });

    test('el resultado se puede validar como cualquier diseño', () {
      final l = const TripPreset().override(
        expandedBottom: LiveProgress.bar(value: bind('progreso')),
      );
      final r = LiveIsland.check(l, const TripPreset().sampleState());
      expect(r.hasErrors, isFalse);
    });
  });
}
