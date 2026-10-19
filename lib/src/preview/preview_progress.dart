import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/enums.dart';
import 'preview_style.dart';

/// Barra continua o por etapas, con puntos, ícono que avanza y etiquetas.
/// Reproduce `progress()` del HTML de prototipos; todo lo que se puede cambiar
/// (grosor, colores, esquinas, espacio, tamaños) viene de `LiveProgressStyle`.
class LivePreviewBar extends StatelessWidget {
  const LivePreviewBar({
    super.key,
    required this.value,
    required this.style,
    this.labels = const [],
    this.segmented = false,
    this.points = false,
    this.showLabels = true,
    this.tracker,
    this.start,
    this.end,
    this.height = 6,
    this.gap = 4,
    this.radius,
    this.pointSize = 10,
    this.pointShape = LivePointShape.circle,
    this.dashed = false,
    this.labelSize = 11.5,
    this.fillColor,
    this.trackColor,
    this.pointColor,
    this.markers = const [],
    this.glow = 0,
    this.endMarker,
    this.stageIcons = const [],
  });

  /// 0 a 1.
  final double value;
  final LiveToneStyle style;
  final List<String> labels;

  /// Un tramo por cada par de etapas (si no, un único tramo).
  final bool segmented;
  final bool points;

  /// Muestra las etiquetas de las etapas.
  final bool showLabels;

  /// Ya compuesto: círculo con ícono, o imagen sin fondo.
  final Widget? tracker;
  final Widget? start, end;

  /// Grosor de la barra.
  final double height;

  /// Separación entre tramos.
  final double gap;

  /// Esquinas (por defecto la mitad del grosor).
  final double? radius;
  final double pointSize;
  final LivePointShape pointShape;

  /// Lo que falta se dibuja como trazo discontinuo.
  final bool dashed;
  final double labelSize;

  /// Colores propios; si faltan se usan los de la superficie.
  final Color? fillColor, trackColor, pointColor;

  /// Posiciones (0 a 1) de marcadores sobre la barra.
  final List<double> markers;

  /// Halo de lo avanzado (radio en pt).
  final double glow;

  /// Marcador pegado al final de la barra (de tamaño [pointSize]).
  final LivePointShape? endMarker;

  /// Un ícono por etapa (ya compuesto), en lugar de los puntos: `pending`
  /// mientras la etapa no llega y `reached` desde que llega.
  final List<({Widget pending, Widget reached})> stageIcons;

  bool get _hasStages => labels.length > 1;

  /// Alto de la fila: lo mayor entre la barra, los íconos de los extremos y los
  /// íconos de etapa.
  double _rowHeight(bool hasEnds) => math.max(
    math.max(height, hasEnds ? 16.0 : 0),
    stageIcons.isEmpty ? 0 : pointSize,
  );
  Color get _fill => fillColor ?? style.fill;
  Color get _track => trackColor ?? style.trackBg;
  double get _radius => radius ?? height / 2;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final hasEnds = start != null || end != null;
    final labelsVisible = showLabels && _hasStages && (segmented || points);

    final bar = SizedBox(
      height: _rowHeight(hasEnds),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (start != null) ...[
            Opacity(opacity: .9, child: start),
            const SizedBox(width: 8),
          ],
          Expanded(child: _track2(v)),
          if (end != null) ...[
            const SizedBox(width: 8),
            Opacity(opacity: .9, child: end),
          ],
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar,
        if (labelsVisible) ...[
          const SizedBox(height: 6),
          if (labels.length > 3) _stageLine(v) else _labels(v),
        ],
      ],
    );
  }

  int _current(double v) =>
      math.min(labels.length - 1, (v * (labels.length - 1) + 1e-6).floor());

  Widget _stageLine(double v) {
    final cur = _current(v);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            labels[cur],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: style.stageStrong,
            ),
          ),
        ),
        Text(
          'Paso ${cur + 1} de ${labels.length}',
          style: TextStyle(fontSize: labelSize, color: style.stageMuted),
        ),
      ],
    );
  }

  Widget _labels(double v) {
    final cur = _current(v);
    final n = labels.length;
    return Padding(
      padding: EdgeInsets.only(
        left: start != null ? 24 : 0,
        right: end != null ? 24 : 0,
      ),
      child: SizedBox(
        height: labelSize + 4.5,
        child: LayoutBuilder(
          builder:
              (context, c) => Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var k = 0; k < n; k++)
                    Positioned(
                      left: k / (n - 1) * c.maxWidth,
                      top: 0,
                      child: FractionalTranslation(
                        translation: Offset(
                          k == 0 ? 0 : (k == n - 1 ? -1 : -.5),
                          0,
                        ),
                        child: Text(
                          labels[k],
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: labelSize,
                            height: 1.4,
                            fontWeight:
                                k == cur ? FontWeight.w600 : FontWeight.w400,
                            color:
                                k == cur ? style.stageStrong : style.stageMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _track2(double v) {
    final rowH = _rowHeight(start != null || end != null);
    final cy = rowH / 2;
    // Con íconos de etapa, la mitad de cada extremo queda dentro del ancho.
    final inset = stageIcons.isEmpty ? 0.0 : pointSize / 2;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: SizedBox(
        height: rowH,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            // Con marcador final la barra termina donde empieza el marcador y el
            // ícono que avanza recorre hasta el centro del marcador.
            final s = endMarker == null ? 0.0 : pointSize;
            final tw = w - s;
            final travel = w - s / 2;
            final f = endMarker == null ? v : math.min(1.0, v * travel / tw);
            final n = _hasStages ? labels.length - 1 : 1;
            final useSegs = segmented && _hasStages;
            final tramos = useSegs ? n : 1;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (glow > 0 && v > 0)
                  Positioned(
                    left: 0,
                    top: cy - height / 2,
                    width: f * tw,
                    height: height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_radius),
                        boxShadow: [
                          BoxShadow(
                            color: _fill.withValues(alpha: .7),
                            blurRadius: glow,
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  top: cy - height / 2,
                  width: tw,
                  height: height,
                  // Con íconos de etapa los tramos terminan antes de cada ícono,
                  // también en los extremos.
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: stageIcons.isEmpty ? 0 : gap / 2,
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < tramos; i++) ...[
                          if (i > 0) SizedBox(width: gap),
                          Expanded(
                            child: _segment(
                              useSegs ? ((f - i / n) * n).clamp(0.0, 1.0) : f,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (stageIcons.isNotEmpty)
                  for (
                    var k = 0;
                    k < stageIcons.length && k < labels.length;
                    k++
                  )
                    Positioned(
                      left: k / (labels.length - 1) * tw,
                      top: cy,
                      child: FractionalTranslation(
                        translation: const Offset(-.5, -.5),
                        child:
                            k / (labels.length - 1) <= f + 1e-6
                                ? stageIcons[k].reached
                                : stageIcons[k].pending,
                      ),
                    )
                else if (points && _hasStages)
                  for (var k = 0; k < labels.length; k++)
                    _dot(
                      k / (labels.length - 1) * tw,
                      k / (labels.length - 1) <= f + 1e-6,
                    ),
                ..._markers(f, tw),
                if (endMarker != null) _dot(tw + s / 2, true, shape: endMarker),
                if (tracker != null)
                  Positioned(
                    left: v * travel,
                    top: cy,
                    child: FractionalTranslation(
                      translation: const Offset(-.5, -.5),
                      child: tracker,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _segment(double f) => ClipRRect(
    borderRadius: BorderRadius.circular(_radius),
    child: SizedBox(
      height: height,
      child: Stack(
        children: [
          if (dashed)
            Positioned.fill(
              child: CustomPaint(painter: _DashPainter(_track, height)),
            )
          else
            Positioned.fill(
              child: DecoratedBox(decoration: BoxDecoration(color: _track)),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: f,
              heightFactor: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: _fill)),
            ),
          ),
        ],
      ),
    ),
  );

  /// Marcadores: el recorrido y el siguiente van de color; los demás, apagados.
  List<Widget> _markers(double v, double w) {
    final sorted = [...markers]..sort();
    final next = sorted.indexWhere((m) => m > v + 1e-6);
    return [
      for (var i = 0; i < sorted.length; i++)
        _dot(sorted[i].clamp(0.0, 1.0) * w, i <= next || next == -1),
    ];
  }

  Widget _dot(double x, bool done, {LivePointShape? shape}) {
    final doneColor = pointColor ?? _fill;
    final sh = shape ?? pointShape;
    final hollow =
        sh == LivePointShape.target || sh == LivePointShape.targetSquare;
    return Positioned(
      left: x,
      top: _rowHeight(start != null || end != null) / 2,
      child: FractionalTranslation(
        translation: const Offset(-.5, -.5),
        child:
            sh == LivePointShape.ring
                ? _ring(done ? doneColor : _track)
                : hollow
                ? Container(
                  width: pointSize,
                  height: pointSize,
                  decoration: BoxDecoration(
                    shape:
                        sh == LivePointShape.target
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                    borderRadius:
                        sh == LivePointShape.targetSquare
                            ? BorderRadius.circular(pointSize * .22)
                            : null,
                    border: Border.all(
                      color: done ? doneColor : style.pendingDot,
                      width: pointSize * .22,
                    ),
                  ),
                )
                : Container(
                  width: pointSize,
                  height: pointSize,
                  decoration: BoxDecoration(
                    shape:
                        sh == LivePointShape.circle
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                    borderRadius:
                        sh == LivePointShape.rounded
                            ? BorderRadius.circular(pointSize / 3)
                            : null,
                    color: done ? doneColor : style.pendingDot,
                    border: Border.all(
                      color: done ? doneColor : _track,
                      width: 2,
                    ),
                  ),
                ),
      ),
    );
  }

  /// Círculo suave con un punto dentro, como un marcador de mapa.
  Widget _ring(Color c) => Container(
    width: pointSize,
    height: pointSize,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: c.withValues(alpha: .25),
    ),
    child: Container(
      width: pointSize * .45,
      height: pointSize * .45,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c),
    ),
  );
}

/// Anillo de progreso con contenido opcional en el centro.
class LivePreviewRing extends StatelessWidget {
  const LivePreviewRing({
    super.key,
    required this.value,
    required this.size,
    required this.color,
    this.child,
    this.strokeWidth = 3,
    this.trackColor,
  });

  final double value;
  final double size;
  final Color color;
  final Widget? child;
  final double strokeWidth;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RingPainter(
        value.clamp(0.0, 1.0),
        color,
        strokeWidth,
        trackColor ?? const Color(0x38FFFFFF),
      ),
      child: child == null ? null : Center(child: child),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.stroke, this.track);

  final double value;
  final Color color;
  final double stroke;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - stroke;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final p =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(rect.center, r, p..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        p..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.stroke != stroke ||
      old.track != track;
}

/// Trazo discontinuo de lo que falta de la barra (rayas del doble del grosor).
class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.thickness);

  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final dash = math.max(thickness * 2.6, 8.0),
        gap = math.max(thickness * 1.8, 6.0);
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, math.min(dash, size.width - x), size.height),
          Radius.circular(thickness / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color || old.thickness != thickness;
}
