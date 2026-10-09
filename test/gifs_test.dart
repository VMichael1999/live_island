import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

/// Genera los cuadros de los GIF del README. Solo corre con
/// `LIVE_ISLAND_GIFS=<carpeta> flutter test test/gifs_test.dart`; luego
/// `python3 tool/make_gifs.py <carpeta>` los une.
void main() {
  final out = Platform.environment['LIVE_ISLAND_GIFS'];

  final cases = <String, LivePreset>{
    'taxi': const TripPreset(),
    'estacionamiento': const ParkingPreset(),
    'delivery': const DeliveryPreset(),
  };

  for (final e in cases.entries) {
    testWidgets('cuadros de ${e.key}', skip: out == null, (tester) async {
      final key = GlobalKey();
      final preset = e.value;
      final layout = preset.build();
      final t0 = DateTime.utc(2026, 10, 4, 15);
      final base = preset.sampleState(now: t0);
      final start = (base['progreso']! as num).toDouble();
      final images = <String, ImageProvider>{
        'asset_packages_live_island_assets_presets_car_png': MemoryImage(
          File('assets/presets/car.png').readAsBytesSync(),
        ),
      };
      await tester.binding.setSurfaceSize(const Size(620, 640));
      tester.view.devicePixelRatio = 2;
      Directory('$out/${e.key}').createSync(recursive: true);

      const frames = 24;
      for (var i = 0; i < frames; i++) {
        final k = i / (frames - 1);
        final state = {...base, 'progreso': start + (1 - start) * k * 0.9};
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
                      width: 300,
                      child: ColoredBox(
                        color: const Color(0xFFF3F4F1),
                        child: LiveIslandPreview(
                          layout: layout,
                          state: state,
                          // La cuenta regresiva avanza 12 s por cuadro.
                          now: t0.add(Duration(seconds: 12 * i)),
                          images: images,
                          appName: preset.appName,
                          androidPromotable: preset.androidPromotable,
                          surfaces: const {
                            LiveSurface.compact,
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
          ),
        );
        await tester.runAsync(() async {
          final ctx = tester.element(find.byType(LiveIslandPreview));
          for (final p in images.values) {
            await precacheImage(p, ctx);
          }
        });
        await tester.pump();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bytes = await tester.runAsync<Uint8List>(() async {
          final img = await boundary.toImage(pixelRatio: 2);
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          return data!.buffer.asUint8List();
        });
        File(
          '$out/${e.key}/${i.toString().padLeft(2, '0')}.png',
        ).writeAsBytesSync(bytes!);
      }
    });
  }
}
