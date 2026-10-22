import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/live_island_kit.dart';

import 'fixtures/html_presets.dart';

class _Call {
  _Call(this.name, this.args);
  final String name;
  final Map<String, Object?> args;
}

class _FakePlatform implements LiveIslandPlatform {
  final calls = <_Call>[];
  bool enabled = true;
  final actionsController = StreamController<String>.broadcast();
  final pushController = StreamController<LivePushEvent>.broadcast();

  List<LiveActivityInfo> active = const [
    LiveActivityInfo('a1'),
    LiveActivityInfo('a2', customId: 'viaje-42'),
  ];

  @override
  Future<List<LiveActivityInfo>> activeActivities() async => active;

  @override
  Future<void> endAll({LiveDismiss dismiss = LiveDismiss.immediate}) async =>
      calls.add(_Call('endAll', {'dismiss': dismiss}));

  @override
  Stream<String> get actions => actionsController.stream;

  @override
  Stream<LivePushEvent> get pushEvents => pushController.stream;

  @override
  Future<void> registerLayout({
    required String name,
    required String layoutJson,
    required List<LiveImagePayload> images,
  }) async => calls.add(
    _Call('registerLayout', {
      'name': name,
      'layout': layoutJson,
      'images': images,
    }),
  );

  @override
  Future<String?> handlePush(Map<String, Object?> data) async {
    calls.add(_Call('handlePush', {'data': data}));
    return 'pushed-1';
  }

  @override
  bool needsAndroidIcons = false;

  @override
  Future<bool> areEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async => enabled;

  @override
  Future<bool> openPromotionSettings() async => false;

  @override
  Future<String> start({
    required String layoutJson,
    required String stateJson,
    required List<LiveImagePayload> images,
    String? deepLink,
    Duration? staleAfter,
    double relevance = 0,
    bool requestPushToken = false,
    String? customId,
  }) async {
    calls.add(
      _Call('start', {
        'customId': customId,
        'requestPushToken': requestPushToken,
        'layout': layoutJson,
        'state': stateJson,
        'images': images,
        'deepLink': deepLink,
        'staleAfter': staleAfter,
        'relevance': relevance,
      }),
    );
    return 'activity-1';
  }

  @override
  Future<void> update(
    String id,
    String stateJson, {
    Duration? staleAfter,
    LiveAlert? alert,
  }) async => calls.add(
    _Call('update', {
      'id': id,
      'state': stateJson,
      'staleAfter': staleAfter,
      'alert': alert,
    }),
  );

  @override
  Future<void> scheduleEnd(
    String id, {
    required double secondsFromNow,
    String? stateJson,
  }) async => calls.add(
    _Call('scheduleEnd', {
      'id': id,
      'secondsFromNow': secondsFromNow,
      'state': stateJson,
    }),
  );

  @override
  Future<void> end(
    String id, {
    String? stateJson,
    LiveDismiss dismiss = LiveDismiss.byDefault,
  }) async => calls.add(
    _Call('end', {'id': id, 'state': stateJson, 'dismiss': dismiss}),
  );
}

const _plain = LiveLayout(theme: LiveTheme(accent: Color(0xFF000000)));

void main() {
  final fx = HtmlFixtures.load();
  late _FakePlatform platform;

  setUp(() {
    platform = _FakePlatform();
    LiveIsland.debugOverride(
      platform: platform,
      imageReader: (img) async => Uint8List.fromList(List.filled(10, 7)),
    );
  });
  tearDown(() => LiveIsland.debugOverride());

  test(
    'start envía el diseño, el estado y las imágenes con su límite',
    () async {
      final p = fx.presets.firstWhere((p) => p.id == 'taxi');
      final act = await LiveIsland.start(
        layout: fx.layoutOf(p, withSmallIcon: false),
        state: fx.stateOf(p),
        deepLink: 'miapp://viaje/1',
        staleAfter: const Duration(minutes: 30),
        relevance: 0.5,
      );
      expect(act.id, 'activity-1');

      final call = platform.calls.single;
      final layout = jsonDecode(call.args['layout']! as String) as Map;
      expect(layout['v'], 1);
      expect((layout['images'] as Map).keys.toSet(), {
        'asset_assets_live_logo_png',
        'asset_assets_live_auto_png',
      });
      final state = jsonDecode(call.args['state']! as String) as Map;
      expect(state['titulo'], 'Your driver is on the way');
      expect(state['llegaA'], p.raw['deadline']);
      expect(call.args['deepLink'], 'miapp://viaje/1');
      expect(call.args['staleAfter'], const Duration(minutes: 30));
      expect(call.args['relevance'], 0.5);

      final images = {
        for (final i in call.args['images']! as List<LiveImagePayload>) i.id: i,
      };
      // Logo: 120 × 120; imagen que avanza: 72 px de alto.
      expect(images['asset_assets_live_logo_png']!.maxWidth, 120);
      expect(images['asset_assets_live_logo_png']!.maxHeight, 120);
      expect(images['asset_assets_live_auto_png']!.maxHeight, 72);
      expect(images['asset_assets_live_auto_png']!.bytes, hasLength(10));
    },
  );

  test('en Android viajan también los PNG de los íconos `android:`', () async {
    platform.needsAndroidIcons = true;
    LiveIsland.debugOverride(
      platform: platform,
      imageReader: (img) async => Uint8List(4),
      assetReader: (path) async => Uint8List.fromList(path.codeUnits),
    );
    final p = fx.presets.firstWhere((p) => p.id == 'taxi');
    await LiveIsland.start(layout: fx.layoutOf(p), state: fx.stateOf(p));
    final images = {
      for (final i
          in platform.calls.single.args['images']! as List<LiveImagePayload>)
        i.id: i,
    };
    expect(
      images.keys,
      containsAll([
        'packages/live_island_kit/assets/icons/mappin.png',
        'packages/live_island_kit/assets/icons/phone.png',
      ]),
    );
    expect(
      images['packages/live_island_kit/assets/icons/phone.png']!.maxWidth,
      96,
    );
    expect(
      images['packages/live_island_kit/assets/icons/phone.png']!.bytes,
      'packages/live_island_kit/assets/icons/phone.png'.codeUnits,
    );
  });

  test('en iOS no se envían los PNG de los íconos', () async {
    final p = fx.presets.firstWhere((p) => p.id == 'taxi');
    await LiveIsland.start(layout: fx.layoutOf(p), state: fx.stateOf(p));
    final ids = [
      for (final i
          in platform.calls.single.args['images']! as List<LiveImagePayload>)
        i.id,
    ];
    expect(ids.where((i) => i.startsWith('assets/')), isEmpty);
  });

  test('las fechas del estado viajan en ISO 8601 UTC', () async {
    await LiveIsland.start(
      layout: _plain,
      state: {'llegaA': DateTime.utc(2026, 10, 4, 15, 6)},
    );
    final state =
        jsonDecode(platform.calls.single.args['state']! as String) as Map;
    expect(state['llegaA'], '2026-10-04T15:06:00.000Z');
  });

  test(
    'un estado de más de 4 096 bytes se rechaza antes de llegar a la plataforma',
    () async {
      expect(
        () => LiveIsland.start(layout: _plain, state: {'x': 'a' * 5000}),
        throwsStateError,
      );
      expect(platform.calls, isEmpty);
    },
  );

  test('una imagen que no se puede leer da un error claro', () async {
    LiveIsland.debugOverride(
      platform: platform,
      imageReader: (img) async => throw Exception('sin red'),
    );
    final p = fx.presets.firstWhere((p) => p.id == 'taxi');
    await expectLater(
      LiveIsland.start(layout: fx.layoutOf(p), state: fx.stateOf(p)),
      throwsA(
        isA<LiveIslandException>().having(
          (e) => e.code,
          'code',
          'image_failed',
        ),
      ),
    );
  });

  test('update envía solo lo que cambia, normalizado', () async {
    final act = await LiveIsland.start(
      layout: _plain,
      state: {'progreso': 0.1},
    );
    await act.update({
      'progreso': 0.8,
      'llegaA': DateTime.utc(2026, 1, 1),
    }, staleAfter: const Duration(minutes: 5));
    final c = platform.calls.last;
    expect(c.name, 'update');
    expect(c.args['id'], 'activity-1');
    expect(jsonDecode(c.args['state']! as String), {
      'progreso': 0.8,
      'llegaA': '2026-01-01T00:00:00.000Z',
    });
    expect(c.args['staleAfter'], const Duration(minutes: 5));
  });

  test(
    'update(deepLink:) cambia a dónde lleva el toque con la clave \$url',
    () async {
      final act = await LiveIsland.start(
        layout: _plain,
        state: {'a': 1},
        deepLink: 'miapp://pedido/42',
      );
      await act.update({'progreso': 0.5}, deepLink: 'miapp://mapa/42');
      expect(jsonDecode(platform.calls.last.args['state']! as String), {
        'progreso': 0.5,
        r'$url': 'miapp://mapa/42',
      });
      // Sin deepLink, el estado no lleva la clave y se conserva el anterior.
      await act.update({'progreso': 0.6});
      expect(jsonDecode(platform.calls.last.args['state']! as String), {
        'progreso': 0.6,
      });
    },
  );

  test('end admite estado final y política de cierre', () async {
    final act = await LiveIsland.start(layout: _plain, state: {'a': 1});
    await act.end(
      state: {'a': 2},
      dismiss: const LiveDismiss.after(Duration(minutes: 5)),
    );
    final c = platform.calls.last;
    expect(c.name, 'end');
    expect(jsonDecode(c.args['state']! as String), {'a': 2});
    final d = c.args['dismiss']! as LiveDismiss;
    expect(d.type, 'after');
    expect(d.after, const Duration(minutes: 5));
  });

  test(
    'requestPermission y openPromotionSettings consultan a la plataforma',
    () async {
      expect(await LiveIsland.requestPermission(), isTrue);
      expect(await LiveIsland.openPromotionSettings(), isFalse);
    },
  );

  test('areEnabled consulta a la plataforma', () async {
    expect(await LiveIsland.areEnabled(), isTrue);
    platform.enabled = false;
    expect(await LiveIsland.areEnabled(), isFalse);
  });

  group('interacción y push', () {
    test('onAction entrega el id de cada botón tocado', () async {
      final ids = <String>[];
      final sub = LiveIsland.onAction(ids.add);
      platform.actionsController
        ..add('llamar')
        ..add('mas_15_min');
      await Future<void>.delayed(Duration.zero);
      expect(ids, ['llamar', 'mas_15_min']);
      await sub.cancel();
      platform.actionsController.add('ignorada');
      await Future<void>.delayed(Duration.zero);
      expect(ids, hasLength(2));
    });

    test('pushTokens separa los de actividad del de push-to-start', () async {
      final tokens = <LivePushToken>[];
      final sub = LiveIsland.pushTokens.listen(tokens.add);
      platform.pushController
        ..add(
          const LivePushTokenEvent(
            LivePushToken(token: 'aa', activityId: 'a1'),
          ),
        )
        ..add(const LivePushTokenEvent(LivePushToken(token: 'bb')))
        ..add(const LivePushStartedEvent('a2'));
      await Future<void>.delayed(Duration.zero);
      expect(tokens.map((t) => t.token), ['aa', 'bb']);
      expect(tokens.map((t) => t.isPushToStart), [false, true]);
      await sub.cancel();
    });

    test('LiveActivity.pushTokens solo trae los de su actividad', () async {
      final act = await LiveIsland.start(
        layout: _plain,
        state: {'a': 1},
        requestPushToken: true,
      );
      expect(platform.calls.single.args['requestPushToken'], isTrue);
      final got = <String>[];
      final sub = act.pushTokens.listen(got.add);
      platform.pushController
        ..add(
          const LivePushTokenEvent(
            LivePushToken(token: 'otro', activityId: 'x'),
          ),
        )
        ..add(
          const LivePushTokenEvent(
            LivePushToken(token: 'mio', activityId: 'activity-1'),
          ),
        );
      await Future<void>.delayed(Duration.zero);
      expect(got, ['mio']);
      await sub.cancel();
    });

    test('startedByPush entrega la actividad iniciada por push', () async {
      final started = <LiveActivity>[];
      final sub = LiveIsland.startedByPush.listen(started.add);
      platform.pushController.add(const LivePushStartedEvent('push-9'));
      await Future<void>.delayed(Duration.zero);
      expect(started.single.id, 'push-9');
      await started.single.update({'progreso': 0.5});
      expect(platform.calls.last.name, 'update');
      expect(platform.calls.last.args['id'], 'push-9');
      await sub.cancel();
    });

    test(
      'stateChanges entrega el ciclo de vida de todas las actividades',
      () async {
        final got = <LiveActivityStateChange>[];
        final sub = LiveIsland.stateChanges.listen(got.add);
        platform.pushController
          ..add(const LivePushStartedEvent('a1'))
          ..add(
            const LivePushStateEvent(
              LiveActivityStateChange('a1', LiveActivityState.active),
            ),
          )
          ..add(
            const LivePushStateEvent(
              LiveActivityStateChange(
                'a2',
                LiveActivityState.dismissed,
                customId: 'viaje-42',
              ),
            ),
          );
        await Future<void>.delayed(Duration.zero);
        expect(got.map((c) => (c.id, c.state, c.customId)), [
          ('a1', LiveActivityState.active, null),
          ('a2', LiveActivityState.dismissed, 'viaje-42'),
        ]);
        await sub.cancel();
      },
    );

    test('LiveActivity.states solo trae los cambios de su actividad', () async {
      final act = await LiveIsland.start(layout: _plain, state: {'a': 1});
      final got = <LiveActivityState>[];
      final sub = act.states.listen(got.add);
      platform.pushController
        ..add(
          const LivePushStateEvent(
            LiveActivityStateChange('otra', LiveActivityState.ended),
          ),
        )
        ..add(
          const LivePushStateEvent(
            LiveActivityStateChange('activity-1', LiveActivityState.stale),
          ),
        )
        ..add(
          const LivePushStateEvent(
            LiveActivityStateChange('activity-1', LiveActivityState.ended),
          ),
        );
      await Future<void>.delayed(Duration.zero);
      expect(got, [LiveActivityState.stale, LiveActivityState.ended]);
      await sub.cancel();
    });

    test(
      'registerLayout guarda el diseño con su nombre y sus imágenes',
      () async {
        final p = fx.presets.firstWhere((p) => p.id == 'taxi');
        await LiveIsland.registerLayout('taxi', fx.layoutOf(p));
        final c = platform.calls.single;
        expect(c.name, 'registerLayout');
        expect(c.args['name'], 'taxi');
        expect((jsonDecode(c.args['layout']! as String) as Map)['v'], 1);
        expect((c.args['images']! as List), isNotEmpty);
      },
    );

    test(
      'activeActivities devuelve las que siguen vivas, listas para actualizar',
      () async {
        final list = await LiveIsland.activeActivities();
        expect(list.map((a) => a.id), ['a1', 'a2']);
        await list.last.update({'progreso': 1});
        expect(platform.calls.last.args['id'], 'a2');
      },
    );

    test('activeActivities trae el id propio de cada actividad', () async {
      final list = await LiveIsland.activeActivities();
      expect(list.map((a) => a.customId), [null, 'viaje-42']);
    });

    test(
      'activity(customId) encuentra la actividad y la deja actualizar',
      () async {
        final a = await LiveIsland.activity('viaje-42');
        expect(a, isNotNull);
        expect(a!.id, 'a2');
        expect(a.customId, 'viaje-42');
        await a.update({'progreso': .5});
        expect(platform.calls.last.args['id'], 'a2');
      },
    );

    test('update pasa el aviso a la plataforma', () async {
      final a = (await LiveIsland.activeActivities()).last;
      await a.update(
        {'estado': 'llegó'},
        alert: const LiveAlert(
          title: 'Arrived',
          body: 'Tu conductor',
          sound: 'a.caf',
        ),
      );
      final sent = platform.calls.last.args['alert']! as LiveAlert;
      expect(sent.title, 'Arrived');
      expect(sent.sound, 'a.caf');
      await a.update({'progreso': .2});
      expect(platform.calls.last.args['alert'], isNull);
    });

    test('scheduleEnd pasa la distancia a la hora y el estado final', () async {
      final a = (await LiveIsland.activeActivities()).last;
      await a.scheduleEnd(
        DateTime.now().add(const Duration(minutes: 30)),
        state: {'estado': 'llegó'},
      );
      final c = platform.calls.last;
      expect(c.name, 'scheduleEnd');
      expect(c.args['id'], 'a2');
      expect(c.args['secondsFromNow'] as double, closeTo(1800, 2));
      expect(c.args['state'], contains('llegó'));
    });

    test('scheduleEnd con una hora pasada termina de inmediato', () async {
      final a = (await LiveIsland.activeActivities()).last;
      await a.scheduleEnd(DateTime.now().subtract(const Duration(minutes: 1)));
      final c = platform.calls.last;
      expect(c.name, 'end');
      expect((c.args['dismiss'] as LiveDismiss).type, 'immediate');
    });

    test('LiveDismiss.at calcula la espera al momento de usarse', () {
      final now = DateTime(2026, 10, 12, 12);
      final d = LiveDismiss.at(now.add(const Duration(minutes: 5)));
      expect(d.type, 'after');
      expect(d.afterFromNow(now), const Duration(minutes: 5));
      expect(
        d.afterFromNow(now.add(const Duration(minutes: 9))),
        Duration.zero,
      );
      expect(LiveDismiss.immediate.afterFromNow(now), Duration.zero);
      expect(
        const LiveDismiss.after(Duration(seconds: 7)).afterFromNow(now),
        const Duration(seconds: 7),
      );
    });

    test('activity devuelve null si no hay una con ese id', () async {
      expect(await LiveIsland.activity('no-existe'), isNull);
    });

    test('start envía el customId y lo conserva en la actividad', () async {
      final act = await LiveIsland.start(
        layout: _plain,
        state: const {'x': 1},
        customId: 'pedido-7',
      );
      expect(act.customId, 'pedido-7');
      expect(platform.calls.single.args['customId'], 'pedido-7');
    });

    test('start sin customId no manda ninguno', () async {
      final act = await LiveIsland.start(layout: _plain, state: const {'x': 1});
      expect(act.customId, isNull);
      expect(platform.calls.single.args['customId'], isNull);
    });

    test(
      'un customId vacío se rechaza antes de llamar a la plataforma',
      () async {
        await expectLater(
          LiveIsland.start(layout: _plain, state: const {}, customId: ''),
          throwsArgumentError,
        );
        expect(platform.calls, isEmpty);
      },
    );

    test('endAll pasa la política de descarte', () async {
      await LiveIsland.endAll();
      expect(platform.calls.single.name, 'endAll');
      expect(
        (platform.calls.single.args['dismiss'] as LiveDismiss).type,
        'immediate',
      );
      await LiveIsland.endAll(
        dismiss: const LiveDismiss.after(Duration(minutes: 5)),
      );
      expect(
        (platform.calls.last.args['dismiss'] as LiveDismiss).after,
        const Duration(minutes: 5),
      );
    });

    test('handlePush pasa los datos a la plataforma', () async {
      final id = await LiveIsland.handlePush({
        'live_island': '{"event":"update"}',
      });
      expect(id, 'pushed-1');
      expect(platform.calls.single.args['data'], {
        'live_island': '{"event":"update"}',
      });
    });
  });

  group('MethodChannelLiveIslandPlatform', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('live_island');
    final log = <MethodCall>[];

    tearDown(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    void mock(Future<Object?> Function(MethodCall) handler) =>
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) {
              log.add(call);
              return handler(call);
            });

    test(
      'serializa start con los nombres que espera el código nativo',
      () async {
        mock((call) async => 'abc');
        final id = await MethodChannelLiveIslandPlatform().start(
          layoutJson: '{}',
          stateJson: '{}',
          images: [
            LiveImagePayload(
              id: 'a',
              bytes: Uint8List(1),
              maxWidth: 120,
              maxHeight: 120,
            ),
          ],
          deepLink: 'x://y',
          staleAfter: const Duration(milliseconds: 1500),
        );
        expect(id, 'abc');
        final args = log.single.arguments as Map;
        expect(log.single.method, 'start');
        expect(
          args.keys,
          containsAll([
            'layout',
            'state',
            'images',
            'deepLink',
            'staleAfter',
            'relevance',
          ]),
        );
        expect(args['staleAfter'], 1.5);
        expect((args['images'] as List).single, containsPair('maxWidth', 120));
      },
    );

    test(
      'scheduleEnd y end con LiveDismiss.at usan los nombres nativos',
      () async {
        mock((call) async => null);
        final p = MethodChannelLiveIslandPlatform();
        await p.scheduleEnd('a', secondsFromNow: 90.5, stateJson: '{"x":1}');
        expect(log.single.method, 'scheduleEnd');
        expect(log.single.arguments, {
          'id': 'a',
          'state': '{"x":1}',
          'dismissAfter': 90.5,
        });
        log.clear();
        await p.end(
          'a',
          dismiss: LiveDismiss.at(
            DateTime.now().add(const Duration(minutes: 2)),
          ),
        );
        final args = log.single.arguments as Map;
        expect(args['dismiss'], 'after');
        expect(args['dismissAfter'] as double, closeTo(120, 2));
      },
    );

    test('update serializa el aviso con title, body y sound', () async {
      mock((call) async => null);
      await MethodChannelLiveIslandPlatform().update(
        'a',
        '{}',
        alert: const LiveAlert(title: 'T', body: 'B', sound: 's.caf'),
      );
      expect((log.single.arguments as Map)['alert'], {
        'title': 'T',
        'body': 'B',
        'sound': 's.caf',
      });
      log.clear();
      await MethodChannelLiveIslandPlatform().update('a', '{}');
      expect((log.single.arguments as Map)['alert'], isNull);
    });

    test(
      'start envía customId y activeActivities lee las dos formas',
      () async {
        mock(
          (call) async => switch (call.method) {
            'start' => 'abc',
            'activeActivities' => [
              'viejo-solo-id',
              {'id': 'n1', 'customId': 'viaje-42'},
              {'id': 'n2', 'customId': null},
            ],
            _ => null,
          },
        );
        final p = MethodChannelLiveIslandPlatform();
        await p.start(
          layoutJson: '{}',
          stateJson: '{}',
          images: const [],
          customId: 'viaje-42',
        );
        expect((log.single.arguments as Map)['customId'], 'viaje-42');
        final list = await p.activeActivities();
        expect(list, [
          const LiveActivityInfo('viejo-solo-id'),
          const LiveActivityInfo('n1', customId: 'viaje-42'),
          const LiveActivityInfo('n2'),
        ]);
        await p.endAll(dismiss: const LiveDismiss.after(Duration(seconds: 90)));
        final args = log.last.arguments as Map;
        expect(log.last.method, 'endAll');
        expect(args['dismiss'], 'after');
        expect(args['dismissAfter'], 90);
      },
    );

    test(
      'convierte los errores de la plataforma en LiveIslandException',
      () async {
        mock(
          (call) async =>
              throw PlatformException(code: 'disabled', message: 'apagado'),
        );
        await expectLater(
          MethodChannelLiveIslandPlatform().areEnabled(),
          throwsA(
            isA<LiveIslandException>()
                .having((e) => e.code, 'code', 'disabled')
                .having((e) => e.message, 'message', 'apagado'),
          ),
        );
      },
    );

    test(
      'sin plugin nativo (Android por ahora) avisa que no está disponible',
      () async {
        await expectLater(
          MethodChannelLiveIslandPlatform().areEnabled(),
          throwsA(
            isA<LiveIslandException>().having(
              (e) => e.code,
              'code',
              'unsupported',
            ),
          ),
        );
      },
    );

    test('end y update envían el id y los segundos', () async {
      mock((call) async => null);
      final p = MethodChannelLiveIslandPlatform();
      await p.update('i1', '{"a":1}', staleAfter: const Duration(seconds: 3));
      await p.end(
        'i1',
        dismiss: const LiveDismiss.after(Duration(seconds: 90)),
      );
      expect(log[0].arguments, containsPair('staleAfter', 3.0));
      expect(log[1].arguments, containsPair('dismiss', 'after'));
      expect(log[1].arguments, containsPair('dismissAfter', 90.0));
    });
  });
}
