import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'preview_style.dart';

/// Barra continua o por etapas, con puntos, ícono que avanza y etiquetas.
/// Reproduce `progress()` del HTML de prototipos.
class LivePreviewBar extends StatelessWidget {
  const LivePreviewBar({
    super.key,
    required this.value,
    required this.style,
    this.labels = const [],
    this.segmented = false,
    this.points = false,
    this.tracker,
    this.start,
    this.end,
  });

  /// 0 a 1.
  final double value;
  final LiveToneStyle style;
  final List<String> labels;

  /// Un tramo por cada par de etapas (si no, un único tramo).
  final bool segmented;
  final bool points;

  /// Ya compuesto: círculo de 26 pt con ícono, o imagen sin fondo.
  final Widget? tracker;
  final Widget? start, end;

  bool get _hasStages => labels.length > 1;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final hasEnds = start != null || end != null;
    final showLabels = _hasStages && (segmented || points);

    final bar = SizedBox(
      height: hasEnds ? 16 : 6,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (start != null) ...[
            Opacity(opacity: .9, child: start),
            const SizedBox(width: 8),
          ],
          Expanded(child: _track(v)),
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
        if (showLabels) ...[
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
    const size = 11.5;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            labels[cur],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w600,
              color: style.stageStrong,
            ),
          ),
        ),
        Text(
          'Paso ${cur + 1} de ${labels.length}',
          style: TextStyle(fontSize: size, color: style.stageMuted),
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
        height: 16,
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
                            fontSize: 11.5,
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

  Widget _track(double v) {
    return SizedBox(
      height: 6,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final n = _hasStages ? labels.length - 1 : 1;
          final useSegs = segmented && _hasStages;
          final tramos = useSegs ? n : 1;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  for (var i = 0; i < tramos; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: _segment(
                        useSegs ? ((v - i / n) * n).clamp(0.0, 1.0) : v,
                      ),
                    ),
                  ],
                ],
              ),
              if (points && _hasStages)
                for (var k = 0; k < labels.length; k++)
                  _dot(
                    k / (labels.length - 1) * w,
                    k / (labels.length - 1) <= v + 1e-6,
                  ),
              if (tracker != null)
                Positioned(
                  left: v * w,
                  top: 3,
                  child: FractionalTranslation(
                    translation: const Offset(-.5, -.5),
                    child: tracker,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(double f) => ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: SizedBox(
      height: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(color: style.trackBg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: f,
            heightFactor: 1,
            child: DecoratedBox(decoration: BoxDecoration(color: style.fill)),
          ),
        ),
      ),
    ),
  );

  Widget _dot(double x, bool done) => Positioned(
    left: x,
    top: 3,
    child: FractionalTranslation(
      translation: const Offset(-.5, -.5),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? style.fill : style.pendingDot,
          border: Border.all(
            color: done ? style.fill : style.trackBg,
            width: 2,
          ),
        ),
      ),
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
  });

  final double value;
  final double size;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RingPainter(value.clamp(0.0, 1.0), color),
      child: child == null ? null : Center(child: child),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color);

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 3;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final p =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(rect.center, r, p..color = const Color(0x38FFFFFF));
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
      old.value != value || old.color != color;
}
