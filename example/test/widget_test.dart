import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';
import 'package:live_island_example/catalog.dart';
import 'package:live_island_example/main.dart';

void main() {
  iniciarDosCasos();

  testWidgets('la lista muestra los 15 presets y el editor', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 4000));
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Editor'), findsOneWidget);
    expect(catalog, hasLength(15));
    for (final e in catalog) {
      expect(find.text(e.label), findsOneWidget);
    }
  });

  testWidgets('un preset muestra su vista previa y su validación', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Estacionamiento'));
    await tester.pumpAndSettle();
    expect(find.text('Estacionamiento activo'), findsWidgets);
    expect(find.text('Validación'), findsOneWidget);
    // Retira la pantalla para cancelar el reloj de la vista previa.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('el editor cambia el título en la vista previa', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Editor'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Título'),
      'Mi título',
    );
    await tester.pump();
    expect(find.text('Mi título'), findsWidgets);
    expect(find.textContaining('final preset = TripPreset()'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

/// Plataforma falsa que recuerda qué actividades hay vivas.
class _RecordingPlatform implements LiveIslandPlatform {
  final alive = <LiveActivityInfo>[];
  final log = <String>[];
  var _n = 0;

  @override
  bool needsAndroidIcons = false;

  @override
  Stream<String> get actions => const Stream.empty();

  @override
  Stream<LivePushEvent> get pushEvents => const Stream.empty();

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<List<LiveActivityInfo>> activeActivities() async => [...alive];

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
    final existing = alive.where((a) => a.customId == customId);
    if (customId != null && existing.isNotEmpty) {
      log.add('update $customId');
      return existing.first.id;
    }
    final id = 'actividad-${++_n}-0000';
    alive.add(LiveActivityInfo(id, customId: customId));
    log.add('start $customId relevance=$relevance');
    return id;
  }

  @override
  Future<void> end(
    String id, {
    String? stateJson,
    LiveDismiss dismiss = LiveDismiss.byDefault,
  }) async {
    alive.removeWhere((a) => a.id == id);
    log.add('end $id');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void iniciarDosCasos() {
  test(
    'iniciar otro caso termina el anterior para que la isla muestre el nuevo',
    () async {
      final platform = _RecordingPlatform();
      LiveIsland.debugOverride(platform: platform);
      addTearDown(() => LiveIsland.debugOverride());

      final taxi = catalog.firstWhere((e) => e.id == 'trip');
      final parking = catalog.firstWhere((e) => e.id == 'parking');

      await model.start(taxi, taxi.preset.build(), taxi.preset.sampleState());
      expect(platform.alive.map((a) => a.customId), ['demo-trip']);

      await model.start(
        parking,
        parking.preset.build(),
        parking.preset.sampleState(),
      );
      // Solo queda la última: es la que muestra la isla.
      expect(platform.alive.map((a) => a.customId), ['demo-parking']);
      expect(platform.log.where((l) => l.startsWith('end')), hasLength(1));
      expect(platform.log.last, contains('relevance=100'));

      // Iniciar el mismo caso otra vez no crea ni termina nada.
      await model.start(
        parking,
        parking.preset.build(),
        parking.preset.sampleState(),
      );
      expect(platform.alive, hasLength(1));
      expect(platform.log.last, 'update demo-parking');
    },
  );
}
