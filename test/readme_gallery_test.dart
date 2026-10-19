// Imágenes de la galería del README: una por diseño, con la isla compacta,
// la expandida y la tarjeta de la pantalla de bloqueo. Se regeneran con:
//   flutter test test/readme_gallery_test.dart --update-goldens
// y quedan en doc/assets/galeria/.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

LiveImage _run(String f, int w, int h, {double? size, double? height}) =>
    LiveImage.asset(
      'assets/run/$f',
      width: w,
      height: h,
      size: size,
      fixedHeight: height,
      shape: LiveShape.square,
    );

void main() {
  final now = DateTime.utc(2026, 10, 4, 15, 0);
  final files = {
    liveDesignCarTopAsset: 'assets/presets/car_top.png',
    liveDesignCarSideAsset: 'assets/presets/car_side.png',
    liveDesignCrestAAsset: 'assets/presets/crest_a.png',
    liveDesignCrestBAsset: 'assets/presets/crest_b.png',
    'assets/run/header.png': 'example/assets/run/header.png',
    'assets/run/avatar.png': 'example/assets/run/avatar.png',
  };
  final images = <String, ImageProvider>{
    for (final e in files.entries)
      LiveImage.asset(e.key).id: MemoryImage(File(e.value).readAsBytesSync()),
  };

  final designs = <String, LivePreset>{
    'marcador': const MatchPreset(),
    'bolsa': const StockPreset(),
    'recogida_clara': RidePickupPreset(
      headerImage: _run('header.png', 760, 308, height: 40),
      driverPhoto: _run('avatar.png', 200, 205, size: 34),
    ),
    'recogida_oscura': RidePickupPreset(
      dark: true,
      headerImage: _run('header.png', 760, 308, height: 40),
      driverPhoto: _run('avatar.png', 200, 205, size: 34),
    ),
    'tienda': const StorePickupPreset(),
    'sala_medica': const WaitingRoomPreset(),
    'vuelo': const FlightPathPreset(),
    'orbita': const OrbitPreset(),
    'tarifa': const FareSplitPreset(),
    'carrera': const RunPreset(),
    'conductor': const RideDriverPreset(),
  };

  for (final e in designs.entries) {
    testWidgets('galería del README: ${e.key}', (tester) async {
      final key = GlobalKey();
      final p = e.value;
      await tester.binding.setSurfaceSize(const Size(460, 520));
      tester.view.devicePixelRatio = 2;
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        final ctx = tester.element(find.byType(SizedBox).first);
        for (final img in images.values) {
          await precacheImage(img, ctx);
        }
      });
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: DefaultTextStyle(
                  style: const TextStyle(fontFamily: 'Roboto'),
                  child: SizedBox(
                    width: 420,
                    child: LiveIslandPreview(
                      layout: p.build(),
                      state: p.sampleState(now: now),
                      now: now,
                      images: images,
                      appName: p.appName,
                      surfaces: const {
                        LiveSurface.compact,
                        LiveSurface.expanded,
                        LiveSurface.lockScreen,
                      },
                      showLabels: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('../doc/assets/galeria/${e.key}.png'),
      );
    });
  }
}
