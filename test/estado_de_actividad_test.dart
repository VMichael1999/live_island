import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/live_island_kit.dart';

/// El canal `live_island/push` tal como lo emiten iOS y Android: un mapa con
/// `type: state`, el id de la actividad, su id propio (vacío si no tiene) y el
/// nombre del estado.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<List<LivePushEvent>> recibir(
    List<Map<String, Object?>> eventos,
  ) async {
    messenger.setMockMethodCallHandler(
      const MethodChannel('live_island/push'),
      (call) async {
        if (call.method == 'listen') {
          for (final e in eventos) {
            await messenger.handlePlatformMessage(
              'live_island/push',
              const StandardMethodCodec().encodeSuccessEnvelope(e),
              (_) {},
            );
          }
        }
        return null;
      },
    );
    final got = <LivePushEvent>[];
    final done = Completer<void>();
    final sub = MethodChannelLiveIslandPlatform().pushEvents.listen((e) {
      got.add(e);
      if (got.length == eventos.length) done.complete();
    });
    await done.future.timeout(const Duration(seconds: 2));
    await sub.cancel();
    return got;
  }

  tearDown(
    () => messenger.setMockMethodCallHandler(
      const MethodChannel('live_island/push'),
      null,
    ),
  );

  test('los cuatro estados llegan con su id y su id propio', () async {
    final got = await recibir([
      for (final s in ['active', 'stale', 'ended', 'dismissed'])
        {
          'type': 'state',
          'activityId': 'a1',
          'customId': 'viaje-42',
          'state': s,
        },
    ]);
    expect(got.cast<LivePushStateEvent>().map((e) => e.change), [
      for (final s in LiveActivityState.values)
        LiveActivityStateChange('a1', s, customId: 'viaje-42'),
    ]);
  });

  test(
    'un id propio vacío es null y un estado desconocido es active',
    () async {
      final got = await recibir([
        {'type': 'state', 'activityId': 'a1', 'customId': '', 'state': 'ended'},
        {'type': 'state', 'activityId': 'a2', 'state': 'nuevo'},
      ]);
      final cambios =
          got.cast<LivePushStateEvent>().map((e) => e.change).toList();
      expect(
        cambios[0],
        const LiveActivityStateChange('a1', LiveActivityState.ended),
      );
      expect(
        cambios[1],
        const LiveActivityStateChange('a2', LiveActivityState.active),
      );
    },
  );

  test('varios oyentes comparten una sola suscripción nativa', () async {
    // Cada `receiveBroadcastStream()` abriría una suscripción nueva en el lado
    // nativo y esa reemplaza a la anterior: el primer oyente dejaba de recibir.
    var listens = 0, cancels = 0;
    messenger.setMockMethodCallHandler(
      const MethodChannel('live_island/push'),
      (call) async {
        if (call.method == 'listen') listens++;
        if (call.method == 'cancel') cancels++;
        return null;
      },
    );
    Future<void> enviar(String activityId, String state) =>
        messenger.handlePlatformMessage(
          'live_island/push',
          const StandardMethodCodec().encodeSuccessEnvelope({
            'type': 'state',
            'activityId': activityId,
            'state': state,
          }),
          (_) {},
        );

    final platform = MethodChannelLiveIslandPlatform();
    final a = <LivePushEvent>[], b = <LivePushEvent>[];
    final subA = platform.pushEvents.listen(a.add);
    final subB = platform.pushEvents.listen(b.add);
    await Future<void>.delayed(Duration.zero);
    expect(listens, 1, reason: 'una sola suscripción nativa para los dos');

    await enviar('x', 'active');
    await Future<void>.delayed(Duration.zero);
    expect([a.length, b.length], [1, 1]);

    // Cancelar uno no corta al otro.
    await subB.cancel();
    await enviar('x', 'ended');
    await Future<void>.delayed(Duration.zero);
    expect(a.length, 2);
    expect(cancels, 0);
    await subA.cancel();
  });

  test('los eventos de push y de estado conviven en el mismo canal', () async {
    final got = await recibir([
      {'type': 'started', 'activityId': 'a1'},
      {'type': 'state', 'activityId': 'a1', 'state': 'active'},
      {'type': 'token', 'activityId': 'a1', 'token': 'ff'},
    ]);
    expect(got[0], isA<LivePushStartedEvent>());
    expect(got[1], isA<LivePushStateEvent>());
    expect(got[2], isA<LivePushTokenEvent>());
  });
}
