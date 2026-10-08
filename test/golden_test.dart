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
}
