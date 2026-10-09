import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';
import 'package:live_island/live_island.dart';
import 'package:live_island/src/preview/preview_progress.dart'
    show LivePreviewBar;

const _rojo = Color(0xFFC62828);
const _gris = Color(0xFFCCCCCC);

LiveSegments _segments({
  bool points = true,
  bool showLabels = true,
  LiveProgressStyle? style,
  LiveTrackerSource? tracker,
  LiveVisual? end,
}) => LiveSegments(
  value: bind('progreso'),
  labels: const ['Asignado', 'En camino', 'Llegó'],
  points: points,
  showLabels: showLabels,
  style: style,
  tracker: tracker,
  endIcon: end,
);

Widget _wrap(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: SingleChildScrollView(child: SizedBox(width: 360, child: child)),
  ),
);

Future<void> _show(
  WidgetTester tester,
  LiveNode bottom, {
  double v = 0.5,
}) async {
  await tester.binding.setSurfaceSize(const Size(500, 900));
  await tester.pumpWidget(
    _wrap(
      LiveExpandedPreview(
        LivePreviewConfig(
          layout: LiveLayout(
            theme: const LiveTheme(accent: Color(0xFF1F6FEB)),
            expanded: LiveExpanded(bottom: bottom),
          ),
          state: {'progreso': v},
          now: DateTime.utc(2026, 10, 4),
        ),
      ),
    ),
  );
}

void main() {
  group('LiveProgressStyle', () {
    test('sin nada indicado no escribe nada en el JSON', () {
      expect(const LiveProgressStyle().isEmpty, isTrue);
      expect(_segments().toJson().containsKey('style'), isFalse);
      expect(
        _segments(
          style: const LiveProgressStyle(),
        ).toJson().containsKey('style'),
        isFalse,
      );
      expect(_segments().toJson().containsKey('showLabels'), isFalse);
    });

    test('ida y vuelta de todos los campos', () {
      const style = LiveProgressStyle(
        height: 10,
        color: _rojo,
        trackColor: _gris,
        gap: 8,
        radius: 2,
        pointSize: 14,
        pointColor: Color(0xFF2E7D32),
        labelSize: 13,
        trackerSize: 32,
      );
      final seg = _segments(style: style, showLabels: false);
      final back =
          LiveNode.fromJson(
                (jsonDecode(jsonEncode(seg.toJson())) as Map)
                    .cast<String, Object?>(),
              )
              as LiveSegments;
      expect(back.style, style);
      expect(back.showLabels, isFalse);
      expect(seg.toJson()['style'], {
        'h': 10,
        'color': '#C62828',
        'trackColor': '#CCCCCC',
        'gap': 8,
        'radius': 2,
        'pointSize': 14,
        'pointColor': '#2E7D32',
        'labelSize': 13,
        'trackerSize': 32,
      });

      final bar = LiveProgress.bar(value: bind('p'), style: style);
      final ring = LiveProgress.ring(
        value: bind('p'),
        style: const LiveProgressStyle(height: 5, color: _rojo),
      );
      for (final n in [bar, ring]) {
        final r = LiveNode.fromJson(
          (jsonDecode(jsonEncode(n.toJson())) as Map).cast<String, Object?>(),
        );
        expect(jsonEncode(r.toJson()), jsonEncode(n.toJson()));
      }
    });

    test('copyWith cambia solo lo indicado', () {
      final s = const LiveProgressStyle(
        height: 8,
        color: _rojo,
      ).copyWith(gap: 2);
      expect(s.height, 8);
      expect(s.color, _rojo);
      expect(s.gap, 2);
    });

    test(
      'el esquema acepta el estilo y rechaza campos inventados o colores malos',
      () {
        final schema = JsonSchema.create(
          File('docs/contract/layout.schema.json').readAsStringSync(),
          schemaVersion: SchemaVersion.draft2020_12,
        );
        Map<String, Object?> layout(Map<String, Object?> node) => {
          'v': 1,
          'theme': {'accent': '#1F6FEB'},
          'regions': {
            'expanded': {'bottom': node},
          },
        };
        final ok = layout(
          _segments(
            style: const LiveProgressStyle(
              height: 10,
              color: _rojo,
              pointSize: 12,
            ),
            showLabels: false,
          ).toJson(),
        );
        expect(schema.validate(jsonDecode(jsonEncode(ok))).isValid, isTrue);

        final inventado = layout({
          ..._segments().toJson(),
          'style': {'grosor': 3},
        });
        expect(schema.validate(inventado).isValid, isFalse);
        final malo = layout({
          ..._segments().toJson(),
          'style': {'color': 'rojo'},
        });
        expect(schema.validate(malo).isValid, isFalse);
        final cero = layout({
          ..._segments().toJson(),
          'style': {'h': 0},
        });
        expect(schema.validate(cero).isValid, isFalse);
      },
    );
  });

  group('la vista previa respeta el estilo', () {
    testWidgets('por defecto: barra de 6, etiquetas y puntos', (tester) async {
      await _show(tester, _segments());
      expect(find.text('Asignado'), findsOneWidget);
      expect(find.text('Llegó'), findsOneWidget);
      final bar = tester.widget<LivePreviewBar>(find.byType(LivePreviewBar));
      expect(bar.height, 6);
      expect(bar.points, isTrue);
    });

    testWidgets('showLabels en false oculta las etiquetas pero deja la barra', (
      tester,
    ) async {
      await _show(tester, _segments(showLabels: false));
      expect(find.text('Asignado'), findsNothing);
      expect(find.text('En camino'), findsNothing);
      expect(find.byType(LivePreviewBar), findsOneWidget);
    });

    testWidgets('el grosor, el color y los puntos llegan a la barra', (
      tester,
    ) async {
      await _show(
        tester,
        _segments(
          points: false,
          style: const LiveProgressStyle(
            height: 12,
            color: _rojo,
            gap: 9,
            pointSize: 20,
          ),
        ),
      );
      final bar = tester.widget<LivePreviewBar>(find.byType(LivePreviewBar));
      expect(bar.height, 12);
      expect(bar.fillColor, _rojo);
      expect(bar.gap, 9);
      expect(bar.points, isFalse);
      expect(bar.pointSize, 20);
    });

    testWidgets('sin tracker ni marcador final no se dibujan', (tester) async {
      await _show(tester, _segments());
      final bar = tester.widget<LivePreviewBar>(find.byType(LivePreviewBar));
      expect(bar.tracker, isNull);
      expect(bar.end, isNull);
      expect(bar.start, isNull);
    });

    testWidgets('con tracker y marcador final sí', (tester) async {
      await _show(
        tester,
        _segments(
          tracker: const LiveIcon.symbol('car.fill'),
          end: const LiveIcon.symbol('mappin'),
        ),
      );
      final bar = tester.widget<LivePreviewBar>(find.byType(LivePreviewBar));
      expect(bar.tracker, isNotNull);
      expect(bar.end, isNotNull);
    });

    testWidgets('el tamaño de las etiquetas', (tester) async {
      await _show(
        tester,
        _segments(style: const LiveProgressStyle(labelSize: 16)),
      );
      expect(tester.widget<Text>(find.text('Asignado')).style!.fontSize, 16);
    });
  });
}
