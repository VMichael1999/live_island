import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_kit/live_island_kit.dart';

void main() {
  test('liveSeries escribe y parseLiveSeries lee la serie', () {
    expect(liveSeries([10, 12.5, 11]), '10,12.5,11');
    expect(parseLiveSeries('10, 12.5,x,11'), [10, 12.5, 11]);
    expect(parseLiveSeries([1, 'a', 2.5]), [1, 2.5]);
    expect(parseLiveSeries(null), isEmpty);
  });

  test('los nodos de gráfica hacen ida y vuelta por JSON', () {
    final nodes = <LiveNode>[
      const LiveSparkline(
        series: LiveBind('serie'),
        height: 50,
        color: Color(0xFF30D158),
        fill: false,
        strokeWidth: 3,
        dot: false,
        min: 0,
        max: 10,
      ),
      LiveGauge(
        value: const LiveBind('p'),
        size: 120,
        sweep: 240,
        knob: false,
        style: LiveProgressStyle(height: 6, dashed: true),
        child: const LiveIcon.symbol('globe'),
      ),
      LiveFlightPath(
        value: const LiveBind('p'),
        height: 60,
        curve: .8,
        tracker: const LiveIcon.symbol('airplane'),
        startIcon: const LiveIcon.symbol('airplane.departure'),
        style: LiveProgressStyle(color: const Color(0xFF30D158)),
      ),
    ];
    for (final n in nodes) {
      final again = LiveNode.fromJson(n.toJson());
      expect(again.toJson(), n.toJson());
      expect(again.runtimeType, n.runtimeType);
    }
  });

  test('los valores por defecto no se escriben en el JSON', () {
    expect(const LiveSparkline(series: LiveBind('s')).toJson(), {
      't': 'spark',
      'bind': 's',
    });
    expect(const LiveGauge(value: LiveBind('p')).toJson(), {
      't': 'gauge',
      'bind': 'p',
    });
  });

  test('en Android el medidor y la ruta cuentan como progreso', () {
    final gauge = LiveGauge(value: const LiveBind('p'));
    final layout = LiveLayout(
      theme: const LiveTheme(accent: Color(0xFF30D158)),
      expanded: LiveExpanded(bottom: gauge),
    );
    final r = LiveIsland.check(layout, {'p': .4});
    expect(r.items.any((c) => c.code == 'ringOnAndroid'), isTrue);
  });
}
