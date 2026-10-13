import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

LiveLayout _layout() => LiveLayout(
  theme: const LiveTheme(accent: Color(0xFF1F6FEB)),
  compactLeading: const LiveText.literal('c'),
  android: const LiveAndroid(title: LiveText.literal('Viaje')),
  expanded: LiveExpanded(
    center: LiveIf(
      LiveBind.stale.isTrue,
      then: const LiveText.literal('Terminado'),
      otherwise: const LiveText(LiveBind('titulo')),
    ),
  ),
);

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(child: SizedBox(width: 380, child: child)),
);

void main() {
  test('LiveBind.stale es el campo reservado \$stale', () {
    expect(LiveBind.stale.field, r'$stale');
    expect(LiveBind.stale.isTrue.toJson(), {
      r'bind': r'$stale',
      'truthy': true,
    });
  });

  test('el diseño con \$stale sigue siendo válido y sin avisos nuevos', () {
    final r = LiveIsland.check(_layout(), const {'titulo': 'En camino'});
    expect(r.items.where((c) => c.severity == LiveSeverity.bad), isEmpty);
  });

  test('el diseño con \$stale ida y vuelta por JSON', () {
    final l = _layout();
    expect(LiveLayout.fromJson(l.toJson()).toJson(), l.toJson());
  });

  testWidgets('la vista previa muestra el estado normal y el desactualizado', (
    tester,
  ) async {
    Widget preview(bool stale) => _host(
      LiveIslandPreview(
        layout: _layout(),
        state: const {'titulo': 'En camino'},
        surfaces: const {LiveSurface.expanded},
        showLabels: false,
        stale: stale,
      ),
    );
    await tester.pumpWidget(preview(false));
    expect(find.text('En camino'), findsOneWidget);
    expect(find.text('Terminado'), findsNothing);

    await tester.pumpWidget(preview(true));
    expect(find.text('Terminado'), findsOneWidget);
    expect(find.text('En camino'), findsNothing);
  });
}
