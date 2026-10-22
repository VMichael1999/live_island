// Pruebas contra la plataforma real: ActivityKit en el simulador de iPhone o las
// notificaciones del emulador de Android, sin dobles de prueba.
//
//   flutter test integration_test -d <simulador o emulador>
//
// En Android el emulador debe tener el permiso de notificaciones:
//   adb shell pm grant com.vmichael1999.live_island_example android.permission.POST_NOTIFICATIONS
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:live_island_kit/live_island_kit.dart';

/// Todos los cambios de estado desde que arrancó la prueba (se escucha desde el
/// principio: los eventos llegan solo mientras alguien escucha).
final cambios = <LiveActivityStateChange>[];

/// Espera hasta [segundos] a que [id] llegue a [state].
Future<void> esperar(
  String id,
  LiveActivityState state, {
  int segundos = 15,
}) async {
  final limite = DateTime.now().add(Duration(seconds: segundos));
  while (!cambios.any((c) => c.id == id && c.state == state)) {
    if (DateTime.now().isAfter(limite)) {
      throw TimeoutException('No llegó $state de $id; llegaron: $cambios');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final layout = const ParkingPreset().build();
  Map<String, Object?> estado([double progreso = 0.2]) => {
    ...const ParkingPreset().sampleState(),
    'progreso': progreso,
  };

  late StreamSubscription<LiveActivityStateChange> escucha;

  setUpAll(() async {
    escucha = LiveIsland.stateChanges.listen(cambios.add);
    expect(
      await LiveIsland.requestPermission(),
      isTrue,
      reason: 'el simulador o emulador debe permitir las actividades',
    );
    expect(await LiveIsland.areEnabled(), isTrue);
  });

  setUp(() async => LiveIsland.endAll());
  tearDownAll(() async {
    await LiveIsland.endAll();
    await escucha.cancel();
  });

  testWidgets('start, update y end con la plataforma real', (tester) async {
    final a = await LiveIsland.start(
      layout: layout,
      state: estado(),
      customId: 'it-flujo',
    );
    expect(a.id, isNotEmpty);

    // Está viva y se encuentra por su id propio.
    expect(
      (await LiveIsland.activeActivities()).map((v) => v.id),
      contains(a.id),
    );
    expect((await LiveIsland.activity('it-flujo'))?.id, a.id);

    // Una actualización no lanza y la actividad sigue viva.
    await a.update({'progreso': 0.6});
    expect(
      (await LiveIsland.activeActivities()).map((v) => v.id),
      contains(a.id),
    );

    // Al terminar sale del sistema.
    await a.end(dismiss: LiveDismiss.immediate);
    await esperar(a.id, LiveActivityState.ended);
    expect(
      (await LiveIsland.activeActivities()).map((v) => v.id),
      isNot(contains(a.id)),
    );
  });

  testWidgets('el ciclo de vida llega en orden: active, ended, dismissed', (
    tester,
  ) async {
    final a = await LiveIsland.start(
      layout: layout,
      state: estado(),
      customId: 'it-estados',
    );
    await esperar(a.id, LiveActivityState.active);
    await a.end(dismiss: LiveDismiss.immediate);
    await esperar(a.id, LiveActivityState.dismissed);

    // En iOS y en Android: active, luego ended y por último dismissed, con su id propio.
    final suyos = cambios.where((c) => c.id == a.id).toList();
    expect(
      suyos.map((c) => c.state),
      containsAllInOrder([
        LiveActivityState.active,
        LiveActivityState.ended,
        LiveActivityState.dismissed,
      ]),
    );
    expect(suyos.every((c) => c.customId == 'it-estados'), isTrue);
  });

  testWidgets('LiveActivity.states entrega los cambios de su actividad', (
    tester,
  ) async {
    final a = await LiveIsland.start(
      layout: layout,
      state: estado(),
      customId: 'it-states',
    );
    final vistos = <LiveActivityState>[];
    final sub = a.states.listen(vistos.add);
    await a.end(dismiss: LiveDismiss.immediate);
    await esperar(a.id, LiveActivityState.dismissed);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await sub.cancel();
    expect(
      vistos,
      containsAllInOrder([
        LiveActivityState.ended,
        LiveActivityState.dismissed,
      ]),
    );
  });

  testWidgets('el mismo id propio actualiza en vez de crear otra', (
    tester,
  ) async {
    final a = await LiveIsland.start(
      layout: layout,
      state: estado(),
      customId: 'it-unica',
    );
    final b = await LiveIsland.start(
      layout: layout,
      state: estado(0.9),
      customId: 'it-unica',
    );
    expect(b.id, a.id);
    expect(
      (await LiveIsland.activeActivities()).where(
        (v) => v.customId == 'it-unica',
      ),
      hasLength(1),
    );
  });

  testWidgets('el link del toque se puede poner y cambiar', (tester) async {
    final a = await LiveIsland.start(
      layout: layout,
      state: estado(),
      deepLink: 'liveisland://app/parking',
      customId: 'it-link',
    );
    await a.update({
      'progreso': 0.5,
    }, deepLink: 'liveisland://app/parking?progress=50');
    expect(
      (await LiveIsland.activeActivities()).map((v) => v.id),
      contains(a.id),
    );
  });

  testWidgets('endAll termina todas las actividades', (tester) async {
    await LiveIsland.start(layout: layout, state: estado(), customId: 'it-a');
    await LiveIsland.start(layout: layout, state: estado(), customId: 'it-b');
    expect(await LiveIsland.activeActivities(), isNotEmpty);
    await LiveIsland.endAll();
    // ActivityKit tarda un instante en retirarlas.
    for (
      var i = 0;
      i < 20 && (await LiveIsland.activeActivities()).isNotEmpty;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    expect(await LiveIsland.activeActivities(), isEmpty);
  });

  testWidgets('actualizar una actividad que no existe da not_found', (
    tester,
  ) async {
    final a = await LiveIsland.start(
      layout: layout,
      state: estado(),
      customId: 'it-fin',
    );
    await a.end(dismiss: LiveDismiss.immediate);
    for (
      var i = 0;
      i < 20 && (await LiveIsland.activeActivities()).isNotEmpty;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    await expectLater(
      a.update({'progreso': 1}),
      throwsA(
        isA<LiveIslandException>().having(
          (e) => e.code,
          'code',
          anyOf('not_found', 'dismissed'),
        ),
      ),
    );
  });
}
