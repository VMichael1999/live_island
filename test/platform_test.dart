import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

import 'fixtures/html_presets.dart';

class _Call {
  _Call(this.name, this.args);
  final String name;
  final Map<String, Object?> args;
}

class _FakePlatform implements LiveIslandPlatform {
  final calls = <_Call>[];
  bool enabled = true;

  @override
  Future<bool> areEnabled() async => enabled;

  @override
  Future<String> start({
    required String layoutJson,
    required String stateJson,
    required List<LiveImagePayload> images,
    String? deepLink,
    Duration? staleAfter,
    double relevance = 0,
  }) async {
    calls.add(
      _Call('start', {
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
  }) async => calls.add(
    _Call('update', {'id': id, 'state': stateJson, 'staleAfter': staleAfter}),
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
      expect(state['titulo'], 'Tu conductor está en camino');
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

  test('areEnabled consulta a la plataforma', () async {
    expect(await LiveIsland.areEnabled(), isTrue);
    platform.enabled = false;
    expect(await LiveIsland.areEnabled(), isFalse);
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
