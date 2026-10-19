import 'package:flutter_test/flutter_test.dart';
import 'package:live_island/live_island.dart';

void main() {
  final cases = <String, LivePreset>{
    'RidePickupPreset (clara)': const RidePickupPreset(),
    'RidePickupPreset (oscura)': const RidePickupPreset(dark: true),
    'StorePickupPreset': const StorePickupPreset(),
    'RunPreset': const RunPreset(),
    'StockPreset': const StockPreset(),
    'FlightPathPreset': const FlightPathPreset(),
    'OrbitPreset': const OrbitPreset(),
  };

  for (final e in cases.entries) {
    group(e.key, () {
      final p = e.value;
      final layout = p.build();
      final state = p.sampleState();

      test('el diseño pasa check() sin errores', () {
        final r = LiveIsland.check(layout, state);
        final bad = r.items.where((c) => c.severity == LiveSeverity.bad);
        expect(bad, isEmpty, reason: bad.map((c) => c.message).join('\n'));
      });

      test('ida y vuelta por JSON (sin el manifiesto de imágenes)', () {
        // El manifiesto lo completa el plugin con los tamaños reales.
        Map<String, Object?> body(LiveLayout l) =>
            {...l.toJson()}..remove('images');
        expect(body(LiveLayout.fromJson(layout.toJson())), body(layout));
      });

      test('el estado de ejemplo cubre todo lo que enlaza el diseño', () {
        final fields = <String>{};
        void walk(LiveNode n) {
          if (n is LiveText && n.source != null) fields.add(n.source!.field);
          if (n is LiveProgress) fields.add(n.value.field);
          if (n is LiveSegments) fields.add(n.value.field);
          if (n is LiveSparkline) fields.add(n.series.field);
          if (n is LiveGauge) fields.add(n.value.field);
          if (n is LiveFlightPath) fields.add(n.value.field);
          if (n is LiveIf) fields.add(n.when.field);
          n.children.forEach(walk);
        }

        final e0 = layout.expanded;
        for (final n in [e0?.leading, e0?.center, e0?.trailing, e0?.bottom]) {
          if (n != null) walk(n);
        }
        final lock = layout.lockScreen?.custom;
        if (lock != null) walk(lock);
        for (final f in fields) {
          expect(
            state.containsKey(f),
            isTrue,
            reason: 'falta "$f" en sampleState',
          );
        }
      });

      test('cabe en 4 096 bytes de estado', () {
        final r = LiveIsland.check(layout, state);
        expect(
          r.items.where(
            (c) => c.code == 'statePayload' && c.severity == LiveSeverity.bad,
          ),
          isEmpty,
        );
      });
    });
  }

  test('la barra de recogida es discontinua y la tarjeta clara es clara', () {
    final j = const RidePickupPreset().build().toJson().toString();
    expect(j, contains('dashed: true'));
    expect(
      const RidePickupPreset().build().theme.background,
      LiveBackground.light,
    );
    expect(
      const RidePickupPreset(dark: true).build().theme.background,
      LiveBackground.system,
    );
  });

  test('el paso actual de la tienda crece según `etapa`', () {
    final j = const StorePickupPreset().build().toJson().toString();
    expect(j, contains('etapa'));
    expect(const StorePickupPreset().sampleState()['etapa'], 1);
  });

  test('el estilo discontinuo viaja en el JSON solo si se activa', () {
    expect(const LiveProgressStyle().toJson().containsKey('dashed'), isFalse);
    const s = LiveProgressStyle(dashed: true);
    expect(s.toJson()['dashed'], true);
    expect(LiveProgressStyle.fromJson(s.toJson()), s);
  });
}
