// Imágenes de la galería del README: una por diseño, con la isla compacta,
// la expandida y la tarjeta de la pantalla de bloqueo. Todas miden lo mismo.
// Solo se generan si pides la variable GENERAR_GALERIA (así una prueba normal
// no toca los archivos):
//   GENERAR_GALERIA=1 flutter test test/readme_gallery_test.dart
// y quedan en doc/assets/galeria/ (la de carga se compone con
// tool/compose_carga.py desde una captura del simulador).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/live_island_kit.dart';

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
    liveDesignCarPlateAsset: 'assets/presets/car_plate.png',
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

  final generar = Platform.environment['GENERAR_GALERIA'] != null;

  Future<void> render(
    WidgetTester tester,
    LivePreset p,
    String out, {
    Set<LiveSurface> surfaces = const {
      LiveSurface.compact,
      LiveSurface.expanded,
      LiveSurface.lockScreen,
    },
    AlignmentGeometry align = Alignment.center,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 14),
  }) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(460, 420));
    tester.view.devicePixelRatio = 3;
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
              // Todas las imágenes miden lo mismo (420 x 380 pt): el diseño
              // va sobre un fondo liso, para que en el README se vean del
              // mismo tamaño.
              child: DefaultTextStyle(
                style: const TextStyle(fontFamily: 'Roboto'),
                child: Container(
                  width: 420,
                  height: 380,
                  alignment: align,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2F4861), Color(0xFF0E1520)],
                    ),
                  ),
                  padding: padding,
                  child: LiveIslandPreview(
                    layout: p.build(),
                    state: p.sampleState(now: now),
                    now: now,
                    images: images,
                    appName: p.appName,
                    surfaces: surfaces,
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
    // A 3x para que se vea nítida en el README.
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 3);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final f = File(out)..createSync(recursive: true);
      f.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  for (final e in designs.entries) {
    testWidgets(
      'galería del README: ${e.key}',
      skip: !generar,
      (tester) => render(tester, e.value, 'doc/assets/galeria/${e.key}.png'),
    );
  }

  // Base de la imagen de carga: la isla compacta y la expandida de la vista
  // previa; la tarjeta con brillo la añade tool/compose_carga.py desde una
  // captura del simulador (la vista previa no dibuja el brillo).
  testWidgets(
    'galería del README: base de la carga',
    skip: !generar,
    (tester) => render(
      tester,
      const ChargePreset(),
      'build/galeria/carga_base.png',
      surfaces: const {LiveSurface.compact, LiveSurface.expanded},
      align: Alignment.topCenter,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
    ),
  );
}
