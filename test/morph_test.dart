import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/live_island_kit.dart';

LiveMorphGeometry _g(double drop, double expand) => LiveMorphGeometry.compute(
  drop: drop,
  expand: expand,
  centerX: 170,
  islandBottom: 49,
  islandHeight: 37,
  dropSize: 52,
  neckMaxWidth: 60,
  cardWidth: 320,
  cardHeight: 90,
  cardRadius: 40,
  cardCenterY: 160,
  canvasWidth: 340,
);

Future<void> _run(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 16; i++) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  group('LiveMorphGeometry', () {
    test('en reposo no hay gota ni cuello', () {
      final g = _g(0, 0);
      expect(g.width, 0);
      expect(g.neckWidth, 0);
    });

    test('el cuello sube, se afina y desaparece al llegar', () {
      final mid = _g(0.4, 0).neck;
      expect(mid, greaterThan(0.5));
      expect(_g(1, 0).neck, 0);
      expect(_g(0.05, 0).neck, lessThan(mid));
    });

    test('la gota se estira al caer y se abre en tarjeta', () {
      final falling = _g(0.45, 0);
      expect(falling.height, greaterThan(falling.width));
      final done = _g(1, 1);
      expect(done.width, closeTo(320, .01));
      expect(done.height, closeTo(90, .01));
      expect(done.offsetY, closeTo(0, .01));
      expect(done.radius, closeTo(40, .01));
    });

    test('un resorte que se pasa de 0 no da medidas negativas', () {
      for (final e in [-0.05, -0.001, 1.08]) {
        final g = _g(-0.02, e);
        expect(g.width, greaterThanOrEqualTo(0));
        expect(g.height, greaterThanOrEqualTo(0));
        expect(g.radius, greaterThanOrEqualTo(0));
      }
    });

    test('la tarjeta nunca se sale del ancho disponible', () {
      expect(_g(1, 1).width, lessThanOrEqualTo(340 - 20));
    });
  });

  group('LiveIslandMorph', () {
    Widget host(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 360, child: child)),
    );

    testWidgets('al mostrarse revela el contenido; al ocultarse lo quita', (
      tester,
    ) async {
      var dismissed = 0;
      Widget w(bool v) => host(
        LiveIslandMorph(
          visible: v,
          cardHeight: 90,
          onDismissed: () => dismissed++,
          child: const Text('Your driver is on the way'),
        ),
      );
      await tester.pumpWidget(w(true));
      Opacity op() => tester.widget<Opacity>(
        find.ancestor(
          of: find.text('Your driver is on the way'),
          matching: find.byType(Opacity),
        ),
      );
      expect(op().opacity, 0);
      await _run(tester, 2500);
      expect(op().opacity, closeTo(1, .02));

      await tester.pumpWidget(w(false));
      await _run(tester, 3000);
      expect(op().opacity, closeTo(0, .02));
      expect(dismissed, 1);
    });

    testWidgets('tocar llama a onTap y deslizar hacia arriba descarta', (
      tester,
    ) async {
      var taps = 0, dismissed = 0;
      await tester.pumpWidget(
        host(
          LiveIslandMorph(
            cardHeight: 90,
            onTap: () => taps++,
            onDismissed: () => dismissed++,
            child: const Text('hola'),
          ),
        ),
      );
      await _run(tester, 2500);
      await tester.tap(find.text('hola'));
      expect(taps, 1);
      await tester.fling(find.text('hola'), const Offset(0, -80), 1500);
      await _run(tester, 100);
      expect(dismissed, 1);
    });
  });
}
