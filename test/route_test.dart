import 'dart:async';
import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

class _Fake implements LiveIslandPlatform {
  final updates = <Map<String, Object?>>[];

  @override
  bool needsAndroidIcons = false;

  @override
  Future<String> start({
    required String layoutJson,
    required String stateJson,
    required List<LiveImagePayload> images,
    String? deepLink,
    Duration? staleAfter,
    double relevance = 0,
    bool requestPushToken = false,
  }) async => 'a1';

  @override
  Future<void> update(
    String id,
    String stateJson, {
    Duration? staleAfter,
  }) async => updates.add(jsonDecode(stateJson) as Map<String, Object?>);

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

void main() {
  // ~1,1 km hacia el este en el ecuador: 0,01° = 1 112 m.
  const a = LiveLatLng(0, 0), b = LiveLatLng(0, 0.01);
  final ruta = LiveRoute.straight(a, b);

  group('LiveRoute', () {
    test('mide el trazado y el avance', () {
      expect(ruta.totalMeters, closeTo(1112, 2));
      expect(ruta.progressAt(a), 0);
      expect(ruta.progressAt(b), 1);
      expect(ruta.progressAt(const LiveLatLng(0, 0.0025)), closeTo(0.25, 0.01));
      expect(ruta.remainingMeters(const LiveLatLng(0, 0.005)), closeTo(556, 3));
    });

    test('una posición fuera del trazado se proyecta y no sale de 0 a 1', () {
      expect(
        ruta.progressAt(const LiveLatLng(0.001, 0.005)),
        closeTo(0.5, 0.01),
      );
      expect(ruta.progressAt(const LiveLatLng(0, -0.02)), 0);
      expect(ruta.progressAt(const LiveLatLng(0, 0.05)), 1);
    });

    test('sigue un trazado con curvas por distancia, no por puntos', () {
      final r = LiveRoute(const [
        LiveLatLng(0, 0),
        LiveLatLng(0, 0.01),
        LiveLatLng(0.01, 0.01),
      ]);
      expect(r.progressAt(const LiveLatLng(0, 0.01)), closeTo(0.5, 0.01));
      expect(r.progressAt(const LiveLatLng(0.005, 0.01)), closeTo(0.75, 0.01));
    });

    test('etapa y llegada', () {
      expect(ruta.stageAt(a, 4), 0);
      expect(ruta.stageAt(const LiveLatLng(0, 0.0035), 4), 1);
      expect(ruta.stageAt(b, 4), 3);
      expect(ruta.hasArrived(const LiveLatLng(0, 0.0099)), isTrue);
      expect(ruta.hasArrived(const LiveLatLng(0, 0.005)), isFalse);
    });

    test('pide al menos dos puntos', () {
      expect(() => LiveRoute(const [a]), throwsArgumentError);
    });
  });

  group('LiveActivity.follow', () {
    late _Fake fake;
    setUp(() {
      fake = _Fake();
      LiveIsland.debugOverride(platform: fake);
    });
    tearDown(() => LiveIsland.debugOverride());

    Future<LiveActivity> open() => LiveIsland.start(
      layout: const LiveLayout(theme: LiveTheme(accent: Color(0xFF000000))),
      state: const {'progreso': 0.0},
    );

    test(
      'envía la primera, agrupa las siguientes y siempre manda la última',
      () async {
        final act = await open();
        final src = StreamController<double>();
        act.follow(
          src.stream,
          (v) => {'progreso': v},
          minInterval: const Duration(milliseconds: 120),
        );
        src.add(.1);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        src.add(.2);
        src.add(.3);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fake.updates, [
          {'progreso': .1},
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(fake.updates, [
          {'progreso': .1},
          {'progreso': .3},
        ]);
        await src.close();
      },
    );

    test('se salta lo que no cambia y deja de seguir al cancelar', () async {
      final act = await open();
      final src = StreamController<double>();
      final sub = act.follow(
        src.stream,
        (v) => {'progreso': v},
        minInterval: Duration.zero,
      );
      src.add(.5);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      src.add(.5);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fake.updates, hasLength(1));
      await sub.cancel();
      src.add(.9);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fake.updates, hasLength(1));
    });

    test('con la ruta: la posición del conductor mueve la barra', () async {
      final act = await open();
      final pos = StreamController<LiveLatLng>();
      act.follow(
        pos.stream,
        (p) => {'progreso': ruta.progressAt(p), 'etapa': ruta.stageAt(p, 4)},
        minInterval: Duration.zero,
      );
      pos.add(const LiveLatLng(0, 0.005));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fake.updates.single['etapa'], 1);
      expect(fake.updates.single['progreso'] as num, closeTo(.5, .01));
      await pos.close();
    });
  });

  group('forma de los puntos', () {
    test('viaja en el JSON solo si se cambia', () {
      expect(
        const LiveProgressStyle().toJson().containsKey('pointShape'),
        isFalse,
      );
      const s = LiveProgressStyle(pointShape: LivePointShape.square);
      expect(s.toJson()['pointShape'], 'square');
      expect(LiveProgressStyle.fromJson(s.toJson()), s);
    });

    test('cuántas etapas: las que se indiquen, con o sin texto', () {
      final seg = LiveSegments(
        value: const LiveBind('p'),
        labels: ['Asignado', '', 'En camino', '', 'Llegó'],
        points: true,
        style: const LiveProgressStyle(pointShape: LivePointShape.rounded),
      );
      expect(LiveSegments.fromJson(seg.toJson()).labels, hasLength(5));
      expect(seg.toJson()['style'], containsPair('pointShape', 'rounded'));
    });
  });
}
