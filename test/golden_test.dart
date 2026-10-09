import 'dart:io';
import 'dart:ui' show Brightness;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

import 'fixtures/html_presets.dart';

/// Imágenes de ejemplo del HTML, por el id que reciben los `LiveImage.asset`
/// del constructor de presets de prueba.
Map<String, ImageProvider> _images() => {
  'asset_assets_live_logo_png': MemoryImage(
    File('test/fixtures/images/logo.png').readAsBytesSync(),
  ),
  'asset_assets_live_auto_png': MemoryImage(
    File('test/fixtures/images/car.png').readAsBytesSync(),
  ),
};

Widget _harness(Key key, double width, Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: Center(
      child: RepaintBoundary(
        key: key,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Roboto'),
          child: SizedBox(
            width: width,
            child: ColoredBox(color: const Color(0xFFF3F4F1), child: child),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  final fx = HtmlFixtures.load();

  Future<void> shoot(
    WidgetTester tester, {
    required HtmlPreset preset,
    required Brightness brightness,
    required bool gallery,
    required String file,
  }) async {
    final key = GlobalKey();
    final width = gallery ? 278.0 : 420.0;
    final preview = LiveIslandPreview(
      layout: fx.layoutOf(preset, withSmallIcon: false),
      state: fx.stateOf(preset),
      now: fx.now,
      images: _images(),
      brightness: brightness,
      appName: preset.app,
      androidPromotable: preset.androidOk,
      surfaces:
          gallery
              ? const {LiveSurface.compact, LiveSurface.lockScreen}
              : const {
                LiveSurface.compact,
                LiveSurface.minimal,
                LiveSurface.expanded,
                LiveSurface.lockScreen,
                LiveSurface.android,
              },
      showLabels: !gallery,
    );
    await tester.binding.setSurfaceSize(Size(width + 40, 1700));
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(_harness(key, width, preview));
    await tester.runAsync(() async {
      for (final p in _images().values) {
        await precacheImage(p, tester.element(find.byType(LiveIslandPreview)));
      }
    });
    await tester.pump();
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/$file.png'));
  }

  group('galería (compact + bloqueo), como las tarjetas del HTML', () {
    for (final p in fx.presets) {
      for (final b in Brightness.values) {
        testWidgets('${p.id} ${b.name}', (tester) async {
          await shoot(
            tester,
            preset: p,
            brightness: b,
            gallery: true,
            file: 'galeria_${p.id}_${b.name}',
          );
        });
      }
    }
  });

  group('vista previa completa (todas las superficies)', () {
    for (final p in fx.presets) {
      for (final b in Brightness.values) {
        testWidgets('${p.id} ${b.name}', (tester) async {
          await shoot(
            tester,
            preset: p,
            brightness: b,
            gallery: false,
            file: 'completa_${p.id}_${b.name}',
          );
        });
      }
    }
  });

  testWidgets('la barra de progreso es editable (tres variantes)', (
    tester,
  ) async {
    final key = GlobalKey();
    LivePreviewConfig cfg(DeliveryPreset p) => LivePreviewConfig(
      layout: p.build(),
      state: p.sampleState(now: fx.now),
      now: fx.now,
      appName: p.appName,
    );
    final variantes = [
      // 1. Por defecto.
      const DeliveryPreset(),
      // 2. Gruesa, roja, con puntos grandes y sin etiquetas.
      const DeliveryPreset(
        showLabels: false,
        progressStyle: LiveProgressStyle(
          height: 14,
          color: Color(0xFFC62828),
          trackColor: Color(0xFF3A2A2A),
          gap: 2,
          pointSize: 18,
          trackerSize: 34,
        ),
      ),
      // 3. Solo la barra: sin puntos, sin etiquetas, sin ícono ni marcador final.
      const DeliveryPreset(
        showLabels: false,
        showPoints: false,
        showTracker: false,
        showEndIcon: false,
        progressStyle: LiveProgressStyle(
          height: 4,
          color: Color(0xFF00897B),
          gap: 0,
        ),
      ),
    ];
    await tester.binding.setSurfaceSize(const Size(420, 700));
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(
      _harness(
        key,
        380,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in variantes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: LiveExpandedPreview(cfg(v)),
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/barra_editable.png'),
    );
  });

  testWidgets('puntos de etapa: forma, cantidad y texto a gusto', (
    tester,
  ) async {
    final key = GlobalKey();
    LivePreviewConfig cfg(DeliveryPreset p) => LivePreviewConfig(
      layout: p.build(),
      state: {...p.sampleState(now: fx.now), 'progreso': 0.5},
      now: fx.now,
      appName: p.appName,
    );
    final variantes = [
      // Cinco puntos cuadrados, sin texto, sin marcador final.
      const DeliveryPreset(
        stages: ['', '', '', '', ''],
        showLabels: false,
        showEndIcon: false,
        progressStyle: LiveProgressStyle(
          pointShape: LivePointShape.square,
          pointSize: 12,
        ),
      ),
      // Tres puntos redondeados con texto.
      const DeliveryPreset(
        stages: ['Recibido', 'En camino', 'Llegó'],
        progressStyle: LiveProgressStyle(
          pointShape: LivePointShape.rounded,
          pointSize: 14,
        ),
      ),
      // Siete puntos circulares, solo la barra y el ícono que avanza.
      const DeliveryPreset(
        stages: ['', '', '', '', '', '', ''],
        showLabels: false,
        showEndIcon: false,
        progressStyle: LiveProgressStyle(pointSize: 8, height: 3, gap: 0),
      ),
    ];
    await tester.binding.setSurfaceSize(const Size(420, 700));
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(
      _harness(
        key,
        380,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in variantes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: LiveExpandedPreview(cfg(v)),
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/puntos_editables.png'),
    );
  });
}
