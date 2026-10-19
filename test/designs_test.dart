import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/live_island_kit.dart';

void main() {
  final cases = <String, LivePreset>{
    'RidePickupPreset (clara)': const RidePickupPreset(),
    'RidePickupPreset (oscura)': const RidePickupPreset(dark: true),
    'RideArrivalPreset': const RideArrivalPreset(),
    'RideTripPreset': const RideTripPreset(),
    'RidePinPreset': const RidePinPreset(),
    'RideStopPreset': const RideStopPreset(),
    'RideDestinationPreset': const RideDestinationPreset(),
    'DeliveryOrderPreset': const DeliveryOrderPreset(),
    'MatchPreset': const MatchPreset(),
    'StorePickupPreset': const StorePickupPreset(),
    'RunPreset': const RunPreset(),
    'StockPreset': const StockPreset(),
    'FlightPathPreset': const FlightPathPreset(),
    'OrbitPreset': const OrbitPreset(),
    'ChargePreset': const ChargePreset(),
    'FareSplitPreset': const FareSplitPreset(),
  };

  for (final e in cases.entries) {
    group(e.key, () {
      final p = e.value;
      final layout = p.build();
      final state = p.sampleState();

      test('el diseño pasa check() sin errores', () {
        final r = LiveIsland.check(layout, state);
        final bad = r.items.where((c) => c.severity == LiveSeverity.bad);
        expect(bad, isEmpty, reason: bad.map((c) => c.message).join('\n'));
      });

      test('ida y vuelta por JSON (sin el manifiesto de imágenes)', () {
        // El manifiesto lo completa el plugin con los tamaños reales.
        Map<String, Object?> body(LiveLayout l) =>
            {...l.toJson()}..remove('images');
        expect(body(LiveLayout.fromJson(layout.toJson())), body(layout));
      });

      test('el estado de ejemplo cubre todo lo que enlaza el diseño', () {
        final fields = <String>{};
        void walk(LiveNode n) {
          if (n is LiveText && n.source != null) fields.add(n.source!.field);
          if (n is LiveProgress) fields.add(n.value.field);
          if (n is LiveSegments) fields.add(n.value.field);
          if (n is LiveSparkline) fields.add(n.series.field);
          if (n is LiveGauge) fields.add(n.value.field);
          if (n is LiveFlightPath) fields.add(n.value.field);
          if (n is LiveSplitBar) {
            for (final p in n.parts) {
              fields.add(p.value.field);
            }
          }
          if (n is LiveIf) fields.add(n.when.field);
          n.children.forEach(walk);
        }

        final e0 = layout.expanded;
        for (final n in [e0?.leading, e0?.center, e0?.trailing, e0?.bottom]) {
          if (n != null) walk(n);
        }
        final lock = layout.lockScreen?.custom;
        if (lock != null) walk(lock);
        for (final f in fields) {
          expect(
            state.containsKey(f),
            isTrue,
            reason: 'falta "$f" en sampleState',
          );
        }
      });

      test('cabe en 4 096 bytes de estado', () {
        final r = LiveIsland.check(layout, state);
        expect(
          r.items.where(
            (c) => c.code == 'statePayload' && c.severity == LiveSeverity.bad,
          ),
          isEmpty,
        );
      });
    });
  }

  test('la barra de recogida es discontinua y la tarjeta clara es clara', () {
    final j = const RidePickupPreset().build().toJson().toString();
    expect(j, contains('dashed: true'));
    expect(
      const RidePickupPreset().build().theme.background,
      LiveBackground.light,
    );
    expect(
      const RidePickupPreset(dark: true).build().theme.background,
      LiveBackground.accent,
    );
  });

  test('el paso actual de la tienda crece según `etapa`', () {
    final j = const StorePickupPreset().build().toJson().toString();
    expect(j, contains('etapa'));
    expect(const StorePickupPreset().sampleState()['etapa'], 1);
  });

  test('el estilo discontinuo viaja en el JSON solo si se activa', () {
    expect(const LiveProgressStyle().toJson().containsKey('dashed'), isFalse);
    const s = LiveProgressStyle(dashed: true);
    expect(s.toJson()['dashed'], true);
    expect(LiveProgressStyle.fromJson(s.toJson()), s);
  });

  test('los marcadores viajan en el JSON y hacen ida y vuelta', () {
    final style = LiveProgressStyle(
      pointShape: LivePointShape.ring,
      markers: const [.4, 1],
    );
    final back = LiveProgressStyle.fromJson(style.toJson());
    expect(back.markers, [.4, 1]);
    expect(back.pointShape, LivePointShape.ring);
    expect(const LiveProgressStyle().isEmpty, isTrue);
  });

  test('el marcador final pegado viaja en el JSON y hace ida y vuelta', () {
    const style = LiveProgressStyle(
      endMarker: LivePointShape.targetSquare,
      pointSize: 16,
    );
    final back = LiveProgressStyle.fromJson(style.toJson());
    expect(back.endMarker, LivePointShape.targetSquare);
    expect(style.toJson()['endMarker'], 'targetSquare');
    expect(
      const LiveProgressStyle().toJson().containsKey('endMarker'),
      isFalse,
    );
    expect(style.isEmpty, isFalse);
  });

  test('los íconos de etapa viajan en el JSON y hacen ida y vuelta', () {
    final seg = LiveSegments(
      value: const LiveBind('progreso'),
      labels: const ['a', 'b'],
      points: true,
      stageIcons: [
        LiveStageIcon(
          pending: LiveImage.reference('p1'),
          reached: LiveImage.reference('r1'),
        ),
        LiveStageIcon(
          pending: LiveImage.reference('p2'),
          reached: LiveImage.reference('r2'),
        ),
      ],
    );
    final back = LiveSegments.fromJson(seg.toJson());
    expect(back.stageIcons, hasLength(2));
    expect(back.stageIcons!.first.reached.id, 'r1');
    expect(back.children.whereType<LiveImage>(), hasLength(4));
  });

  test('ningún texto de ejemplo mezcla inglés y español', () {
    final english = RegExp(
      r'\b(until|pickup|arriving|soon|order|progress|handcrafting|miles|time|home|guest|stats|world cup|landing|on time)\b',
      caseSensitive: false,
    );
    for (final p in <LivePreset>[
      const RidePickupPreset(),
      const RidePickupPreset(dark: true),
      const RideArrivalPreset(),
      const RideTripPreset(),
      const RidePinPreset(),
      const RideStopPreset(),
      const RideDestinationPreset(),
      const DeliveryOrderPreset(),
      const StorePickupPreset(),
      const RunPreset(),
      const MatchPreset(),
      const StockPreset(),
      const FlightPathPreset(),
      const OrbitPreset(),
      const ChargePreset(),
      const FareSplitPreset(),
    ]) {
      final texts = [
        ...p.sampleState().values.whereType<String>(),
        for (final n in p.build().allNodes)
          if (n is LiveText) ...[
            if (n.literal != null) n.literal!,
            if (n.template != null) n.template!,
          ],
      ];
      final text = texts.join(' | ');
      expect(english.hasMatch(text), isFalse, reason: '${p.runtimeType}');
    }
  });

  test(
    'una imagen con alto fijo viaja en el JSON y conserva su ancho libre',
    () {
      final img = LiveImage.asset(
        'assets/x.png',
        width: 760,
        height: 308,
      ).withHeight(40);
      expect(img.toJson()['h'], 40);
      expect(img.toJson().containsKey('size'), isFalse);
      final back = LiveImage.fromJson(img.toJson());
      expect(back.fixedHeight, 40);
      expect(
        img.withSize(30).fixedHeight,
        40,
        reason: 'withSize no pierde el alto',
      );
    },
  );

  test(
    'borde y brillo de la caja, brillo de la barra, tramos y cursiva viajan en el JSON',
    () {
      final box = LiveBox(
        color: const Color(0xFF000000),
        border: const Color(0xFF30D158),
        borderWidth: 2,
        glow: 12,
      );
      final back = LiveNode.fromJson(box.toJson()) as LiveBox;
      expect(back.border, const Color(0xFF30D158));
      expect(back.borderWidth, 2);
      expect(back.glow, 12);

      expect(
        LiveProgressStyle.fromJson(LiveProgressStyle(glow: 8).toJson()).glow,
        8,
      );

      const split = LiveSplitBar([
        LiveSplitPart(LiveBind('a'), Color(0xFFFFFFFF)),
        LiveSplitPart(LiveBind('b'), Color(0xFF30D158)),
      ], height: 12);
      final s2 = LiveNode.fromJson(split.toJson()) as LiveSplitBar;
      expect(s2.parts, hasLength(2));
      expect(s2.height, 12);
      expect(s2.parts.last.color, const Color(0xFF30D158));

      const t = LiveText.literal('Run', italic: true);
      expect(t.toJson()['i'], true);
      expect((LiveNode.fromJson(t.toJson()) as LiveText).italic, isTrue);
      expect(const LiveText.literal('x').toJson().containsKey('i'), isFalse);
    },
  );

  test('el bloque Android admite imagen grande, subtexto y barra partida', () {
    final foto = LiveImage.asset('assets/foto.png', size: 44);
    final android = LiveAndroid(
      title: const LiveText.literal('T'),
      subText: const LiveBind('vehiculo'),
      largeIcon: foto,
      progress: const LiveSplitBar([
        LiveSplitPart(LiveBind('a'), Color(0xFFFFFFFF)),
      ]),
    );
    final back = LiveAndroid.fromJson(android.toJson());
    expect(back.largeIcon, isA<LiveImage>());
    expect((back.largeIcon! as LiveImage).id, foto.id);
    expect(back.progress, isA<LiveSplitBar>());
    expect(back.toJson()['subText'], {'bind': 'vehiculo'});

    // La imagen grande entra en el manifiesto de imágenes del diseño.
    final layout = LiveLayout(
      theme: const LiveTheme(accent: Color(0xFF000000)),
      android: android,
    );
    expect(layout.images.map((i) => i.id), contains(foto.id));
  });

  test(
    'en Android la tarifa viaja como barra partida y los demás ponen su imagen',
    () {
      expect(
        const FareSplitPreset().build().android!.progress,
        isA<LiveSplitBar>(),
      );
      final crest = const MatchPreset().build().android!.largeIcon;
      expect(crest, isA<LiveImage>());
      final withLogo =
          StockPreset(
            brandLogo: LiveImage.asset('assets/logo.png', size: 28),
          ).build().android!.largeIcon;
      expect(withLogo, isA<LiveImage>());
      expect(const StockPreset().build().android!.largeIcon, isNull);
    },
  );

  test(
    'el estilo tarjeta de Android viaja en el JSON y entra en el manifiesto',
    () {
      final crest = LiveImage.asset('assets/escudo.png', size: 40);
      final android = LiveAndroid(
        title: const LiveText.literal('T'),
        style: LiveAndroidStyle.card,
        card: LiveRow([crest, const LiveText.literal('3 : 1')]),
        cardCollapsed: const LiveText.literal('3 : 1'),
      );
      final json = android.toJson();
      expect(json['style'], 'card');
      final back = LiveAndroid.fromJson(json);
      expect(back.style, LiveAndroidStyle.card);
      expect(back.card, isA<LiveRow>());
      expect(back.cardCollapsed, isA<LiveText>());
      // Sin estilo tarjeta el campo no viaja.
      expect(
        const LiveAndroid(
          title: LiveText.literal('T'),
        ).toJson().containsKey('style'),
        isFalse,
      );
      final layout = LiveLayout(
        theme: const LiveTheme(accent: Color(0xFF000000)),
        android: android,
      );
      expect(layout.images.map((i) => i.id), contains(crest.id));
    },
  );

  test(
    'el marcador y la bolsa usan la tarjeta en Android; la tarifa, el estilo nativo',
    () {
      expect(const MatchPreset().build().android!.style, LiveAndroidStyle.card);
      expect(const StockPreset().build().android!.style, LiveAndroidStyle.card);
      expect(
        const FareSplitPreset().build().android!.style,
        LiveAndroidStyle.liveUpdate,
      );
      expect(
        const MatchPreset(
          androidStyle: LiveAndroidStyle.liveUpdate,
        ).build().android!.style,
        LiveAndroidStyle.liveUpdate,
      );
    },
  );
}
