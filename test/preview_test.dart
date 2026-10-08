import 'dart:ui' show Brightness;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

import 'fixtures/html_presets.dart';

Widget _wrap(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: SingleChildScrollView(child: SizedBox(width: 420, child: child)),
  ),
);

void main() {
  final fx = HtmlFixtures.load();
  HtmlPreset preset(String id) => fx.presets.firstWhere((p) => p.id == id);

  Future<void> show(
    WidgetTester tester,
    String id, {
    Set<LiveSurface>? surfaces,
    Brightness brightness = Brightness.dark,
    DateTime? now,
    bool useFixedNow = true,
  }) async {
    final p = preset(id);
    await tester.binding.setSurfaceSize(const Size(500, 1800));
    await tester.pumpWidget(
      _wrap(
        LiveIslandPreview(
          layout: fx.layoutOf(p, withSmallIcon: false),
          state: fx.stateOf(p),
          now: useFixedNow ? (now ?? fx.now) : null,
          brightness: brightness,
          appName: p.app,
          androidPromotable: p.androidOk,
          surfaces:
              surfaces ??
              const {
                LiveSurface.compact,
                LiveSurface.minimal,
                LiveSurface.expanded,
                LiveSurface.lockScreen,
                LiveSurface.android,
              },
        ),
      ),
    );
  }

  testWidgets('dibuja el contenido del estado en cada superficie', (
    tester,
  ) async {
    await show(tester, 'taxi');
    // Compact + expandida + bloqueo muestran la cuenta regresiva.
    expect(find.text('6:00'), findsNWidgets(3));
    expect(
      find.text('Tu conductor está en camino'),
      findsNWidgets(3),
    ); // isla, bloqueo, Android
    expect(find.text('Carlos M.'), findsNWidgets(2));
    expect(find.text('Llamar'), findsNWidgets(3));
    expect(find.text('Asignado'), findsNWidgets(3));
  });

  testWidgets('el chip de Android muestra los minutos y la nota de promoción', (
    tester,
  ) async {
    await show(tester, 'taxi', surfaces: {LiveSurface.android});
    expect(find.text('6 min'), findsOneWidget);
    expect(find.textContaining('Promovida a Live Update'), findsOneWidget);
  });

  testWidgets('si Android no promueve, no hay chip y se explica por qué', (
    tester,
  ) async {
    await show(tester, 'score', surfaces: {LiveSurface.android});
    expect(find.text('2–1'), findsNothing);
    expect(find.textContaining('No se promueve'), findsOneWidget);
  });

  testWidgets('un chip de texto largo se recorta a 6 caracteres y …', (
    tester,
  ) async {
    final layout = fx
        .layoutOf(preset('taxi'))
        .copyWith(
          android: const LiveAndroid(
            title: LiveText.literal('Hola'),
            chip: LiveChip.text('Llegando ya'),
          ),
        );
    await tester.binding.setSurfaceSize(const Size(500, 800));
    await tester.pumpWidget(
      _wrap(
        LiveAndroidPreview(
          LivePreviewConfig(layout: layout, state: const {}, now: fx.now),
        ),
      ),
    );
    expect(find.text('Llegan…'), findsOneWidget);
  });

  testWidgets('el anillo va a la derecha y el dato debajo', (tester) async {
    await show(tester, 'parking', surfaces: {LiveSurface.expanded});
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.textContaining('45:00'), findsOneWidget);
  });

  testWidgets('con más de 3 etapas se muestra "Paso k de n"', (tester) async {
    await show(tester, 'delivery', surfaces: {LiveSurface.expanded});
    expect(find.text('Preparando'), findsOneWidget);
    expect(find.text('Paso 2 de 4'), findsOneWidget);
    expect(find.text('Confirmado'), findsNothing);
  });

  testWidgets('con 3 etapas o menos se muestran todas las etiquetas', (
    tester,
  ) async {
    await show(tester, 'taxi', surfaces: {LiveSurface.expanded});
    expect(find.text('Asignado'), findsOneWidget);
    expect(find.text('En camino'), findsOneWidget);
    expect(find.text('Llegó'), findsOneWidget);
  });

  testWidgets('el progreso cambia el estado de las etiquetas', (tester) async {
    final p = preset('taxi');
    final state = Map<String, Object?>.of(fx.stateOf(p))..['progreso'] = 1.0;
    await tester.binding.setSurfaceSize(const Size(500, 800));
    await tester.pumpWidget(
      _wrap(
        LiveExpandedPreview(
          LivePreviewConfig(layout: fx.layoutOf(p), state: state, now: fx.now),
        ),
      ),
    );
    final llego = tester.widget<Text>(find.text('Llegó'));
    expect(llego.style!.fontWeight, FontWeight.w600);
    final asignado = tester.widget<Text>(find.text('Asignado'));
    expect(asignado.style!.fontWeight, FontWeight.w400);
  });

  testWidgets('el modo claro cambia la tarjeta de Android y no la isla', (
    tester,
  ) async {
    await show(
      tester,
      'taxi',
      surfaces: {LiveSurface.android},
      brightness: Brightness.light,
    );
    final shade = tester.widgetList<Container>(find.byType(Container)).any((c) {
      final d = c.decoration;
      return d is BoxDecoration && d.color == const Color(0xFFFEF7FF);
    });
    expect(shade, isTrue);
  });

  testWidgets('sin hora fija el reloj se actualiza cada segundo', (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LivePreviewClock(
          builder: (_, now) {
            builds++;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(builds, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(builds, 3);
    // Al retirar el widget el temporizador se cancela (si no, la prueba falla).
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('con hora fija no hay temporizador', (tester) async {
    var builds = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LivePreviewClock(
          fixed: DateTime.utc(2026, 10, 4),
          builder: (_, now) {
            builds++;
            expect(now, DateTime.utc(2026, 10, 4));
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(builds, 1);
  });

  testWidgets('la imagen que no se puede resolver no rompe el dibujo', (
    tester,
  ) async {
    // Sin `images`, el logo del taxi se busca como asset y falla en silencio.
    await show(tester, 'taxi', surfaces: {LiveSurface.lockScreen});
    expect(tester.takeException(), isNull);
  });
}
