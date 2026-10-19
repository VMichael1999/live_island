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

  testWidgets('diseños de referencia con las imágenes de la app de ejemplo', (
    tester,
  ) async {
    final key = GlobalKey();
    const names = [
      'uber',
      'uber_white',
      'starbucks',
      'nike',
      'psg',
      'chelsea',
      'ride_head_light',
      'ride_car_light',
      'ride_head_dark',
      'ride_car_dark',
    ];
    final images = <String, ImageProvider>{
      for (final n in names)
        'asset_assets_reference_${n}_png': MemoryImage(
          File('example/assets/reference/$n.png').readAsBytesSync(),
        ),
    };
    LiveImage ref(String f, double w, double h) => LiveImage.asset(
      'assets/reference/$f',
      width: w.round(),
      height: h.round(),
      size: w,
      shape: LiveShape.square,
    );
    final presets = <LivePreset>[
      RidePickupPreset(
        brandLogo: ref('uber.png', 70, 24),
        headerImage: ref('ride_head_light.png', 102, 42),
        trackerImage: ref('ride_car_light.png', 46, 26),
      ),
      RidePickupPreset(
        dark: true,
        brandLogo: ref('uber_white.png', 64, 22),
        headerImage: ref('ride_head_dark.png', 118, 47),
        trackerImage: ref('ride_car_dark.png', 44, 24),
      ),
      StorePickupPreset(brandLogo: ref('starbucks.png', 28, 28)),
      RunPreset(brandMark: ref('nike.png', 56, 20)),
      MatchPreset(
        homeCrest: ref('psg.png', 84, 84),
        awayCrest: ref('chelsea.png', 84, 84),
      ),
    ];
    await tester.binding.setSurfaceSize(const Size(900, 1900));
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(SizedBox).first);
      for (final p in images.values) {
        await precacheImage(p, ctx);
      }
    });
    await tester.pumpWidget(
      _harness(
        key,
        860,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final p in presets)
              SizedBox(
                width: 420,
                child: LiveIslandPreview(
                  layout: p.build(),
                  state: p.sampleState(now: fx.now),
                  now: fx.now,
                  images: images,
                  appName: p.appName,
                  surfaces: const {
                    LiveSurface.expanded,
                    LiveSurface.lockScreen,
                  },
                  showLabels: false,
                ),
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/disenos_referencia.png'),
    );
  });

  testWidgets('golden: gráficas (bolsa, vuelo y órbita)', (tester) async {
    final key = GlobalKey();
    final presets = <LivePreset>[
      const StockPreset(),
      const FlightPathPreset(),
      const OrbitPreset(),
    ];
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(
      _harness(
        key,
        860,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final p in presets)
              SizedBox(
                width: 420,
                child: LiveIslandPreview(
                  layout: p.build(),
                  state: p.sampleState(now: fx.now),
                  now: fx.now,
                  appName: p.appName,
                  surfaces: const {
                    LiveSurface.expanded,
                    LiveSurface.lockScreen,
                    LiveSurface.android,
                  },
                  showLabels: false,
                ),
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/graficas.png'),
    );
  });
}
