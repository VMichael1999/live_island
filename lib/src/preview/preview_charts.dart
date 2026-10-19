import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Gráfica de línea con área opcional y punto final.
class LivePreviewSparkline extends StatelessWidget {
  const LivePreviewSparkline({
    super.key,
    required this.values,
    required this.height,
    required this.color,
    this.fill = true,
    this.strokeWidth = 2,
    this.dot = true,
    this.min,
    this.max,
  });

  final List<double> values;
  final double height;
  final Color color;
  final bool fill;
  final double strokeWidth;
  final bool dot;
  final double? min;
  final double? max;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _SparkPainter(this)),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.w);

  final LivePreviewSparkline w;

  @override
  void paint(Canvas canvas, Size size) {
    if (w.values.length < 2) return;
    final lo = w.min ?? w.values.reduce(math.min);
    var hi = w.max ?? w.values.reduce(math.max);
    if (hi - lo < 1e-9) hi = lo + 1;
    final pad = w.strokeWidth + (w.dot ? 3.5 : 0);
    final usableW = size.width - pad * 2, usableH = size.height - pad * 2;
    final pts = <Offset>[
      for (var i = 0; i < w.values.length; i++)
        Offset(
          pad + usableW * i / (w.values.length - 1),
          pad + usableH * (1 - ((w.values[i] - lo) / (hi - lo)).clamp(0, 1)),
        ),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final mid = Offset(
        (pts[i - 1].dx + pts[i].dx) / 2,
        (pts[i - 1].dy + pts[i].dy) / 2,
      );
      if (i == 1) {
        line.lineTo(mid.dx, mid.dy);
      } else {
        line.quadraticBezierTo(pts[i - 1].dx, pts[i - 1].dy, mid.dx, mid.dy);
      }
    }
    line.lineTo(pts.last.dx, pts.last.dy);

    if (w.fill) {
      final area =
          Path.from(line)
            ..lineTo(pts.last.dx, size.height)
            ..lineTo(pts.first.dx, size.height)
            ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
            w.color.withValues(alpha: .35),
            w.color.withValues(alpha: 0),
          ]),
      );
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = w.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (w.dot) {
      canvas.drawCircle(pts.last, 3.5, Paint()..color = w.color);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.w.values != w.values ||
      old.w.color != w.color ||
      old.w.min != w.min ||
      old.w.max != w.max ||
      old.w.fill != w.fill ||
      old.w.dot != w.dot ||
      old.w.strokeWidth != w.strokeWidth;
}

/// Medidor de arco de [size] de ancho que abarca [sweep] grados.
class LivePreviewGauge extends StatelessWidget {
  const LivePreviewGauge({
    super.key,
    required this.value,
    required this.size,
    required this.sweep,
    required this.color,
    required this.trackColor,
    required this.stroke,
    this.knob = true,
    this.dashed = false,
    this.child,
  });

  final double value;
  final double size;
  final double sweep;
  final Color color;
  final Color trackColor;
  final double stroke;
  final bool knob;
  final bool dashed;
  final Widget? child;

  double get _pad => math.max(stroke / 2, knob ? stroke * .9 : 0) + 1;
  double get _radius => size / 2 - _pad;
  double get _height =>
      _radius * (1 - math.cos(sweep.clamp(90, 360) * math.pi / 360)) + _pad * 2;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: _height,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned.fill(child: CustomPaint(painter: _GaugePainter(this))),
        if (child != null)
          Padding(padding: EdgeInsets.only(bottom: _pad), child: child),
      ],
    ),
  );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.g);

  final LivePreviewGauge g;

  @override
  void paint(Canvas canvas, Size size) {
    final r = g._radius, pad = g._pad;
    final centre = Offset(size.width / 2, pad + r);
    final sweep = g.sweep.clamp(90, 360) * math.pi / 180;
    final start = -math.pi / 2 - sweep / 2;
    final rect = Rect.fromCircle(center: centre, radius: r);
    final track =
        Paint()
          ..color = g.trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = g.stroke
          ..strokeCap = StrokeCap.round;
    final v = g.value.clamp(0.0, 1.0);
    if (g.dashed) {
      final arc = Path()..addArc(rect, start, sweep);
      final dash = math.max(g.stroke * 1.4, 5.0),
          gap = math.max(g.stroke * 1.2, 4.0);
      for (final m in arc.computeMetrics()) {
        for (double d = 0; d < m.length; d += dash + gap) {
          canvas.drawPath(
            m.extractPath(d, math.min(d + dash, m.length)),
            track,
          );
        }
      }
    } else {
      canvas.drawArc(rect, start, sweep, false, track);
    }
    if (v > 0) {
      canvas.drawArc(
        rect,
        start,
        sweep * v,
        false,
        Paint()
          ..color = g.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = g.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
    if (g.knob) {
      final a = start + sweep * v;
      final p = centre + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(p, g.stroke * .9, Paint()..color = g.color);
      canvas.drawCircle(
        p,
        g.stroke * .9,
        Paint()
          ..color = const Color(0x66000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.g.value != g.value ||
      old.g.color != g.color ||
      old.g.trackColor != g.trackColor ||
      old.g.sweep != g.sweep ||
      old.g.stroke != g.stroke ||
      old.g.knob != g.knob ||
      old.g.dashed != g.dashed;
}

/// Ruta curva (arco) con lo recorrido, lo que falta y un ícono que avanza.
class LivePreviewPath extends StatelessWidget {
  const LivePreviewPath({
    super.key,
    required this.value,
    required this.height,
    required this.curve,
    required this.color,
    required this.trackColor,
    required this.stroke,
    this.dashed = true,
    this.tracker,
    this.start,
    this.end,
  });

  final double value;
  final double height;
  final double curve;
  final Color color;
  final Color trackColor;
  final double stroke;
  final bool dashed;
  final Widget? tracker;
  final Widget? start;
  final Widget? end;

  static const double _inset = 14;

  /// Punto de la curva (cuadrática) en `t` para un cuadro [size].
  static Offset pointAt(Size size, double curve, double t) {
    final p0 = Offset(_inset, size.height - _inset);
    final p2 = Offset(size.width - _inset, size.height - _inset);
    final apex = curve.clamp(0.0, 1.0) * (size.height - _inset * 2);
    final p1 = Offset(size.width / 2, p0.dy - 2 * apex);
    final u = 1 - t;
    return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, height);
        final v = value.clamp(0.0, 1.0);
        final at = pointAt(size, curve, v);
        final a = pointAt(size, curve, 0), b = pointAt(size, curve, 1);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _PathPainter(this))),
            if (start != null)
              Positioned(
                left: a.dx,
                top: a.dy,
                child: FractionalTranslation(
                  translation: const Offset(-.5, -.5),
                  child: start!,
                ),
              ),
            if (end != null)
              Positioned(
                left: b.dx,
                top: b.dy,
                child: FractionalTranslation(
                  translation: const Offset(-.5, -.5),
                  child: end!,
                ),
              ),
            if (tracker != null)
              Positioned(
                left: at.dx,
                top: at.dy,
                child: FractionalTranslation(
                  translation: const Offset(-.5, -.5),
                  child: tracker!,
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.w);

  final LivePreviewPath w;

  Path _curve(Size size, double from, double to) {
    final path = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final t = from + (to - from) * i / steps;
      final p = LivePreviewPath.pointAt(size, w.curve, t);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = w.value.clamp(0.0, 1.0);
    final track =
        Paint()
          ..color = w.trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = w.stroke
          ..strokeCap = StrokeCap.round;
    final rest = _curve(size, v, 1);
    if (w.dashed) {
      final dash = math.max(w.stroke * 2.2, 6.0),
          gap = math.max(w.stroke * 1.8, 5.0);
      for (final m in rest.computeMetrics()) {
        for (double d = 0; d < m.length; d += dash + gap) {
          canvas.drawPath(
            m.extractPath(d, math.min(d + dash, m.length)),
            track,
          );
        }
      }
    } else {
      canvas.drawPath(rest, track);
    }
    if (v > 0) {
      canvas.drawPath(
        _curve(size, 0, v),
        Paint()
          ..color = w.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.w.value != w.value ||
      old.w.curve != w.curve ||
      old.w.color != w.color ||
      old.w.trackColor != w.trackColor ||
      old.w.stroke != w.stroke ||
      old.w.dashed != w.dashed;
}

/// Barra partida en tramos de color, en proporción a sus valores.
class LivePreviewSplit extends StatelessWidget {
  const LivePreviewSplit({
    super.key,
    required this.values,
    required this.colors,
    required this.height,
    required this.gap,
    this.radius,
  });

  final List<double> values;
  final List<Color> colors;
  final double height;
  final double gap;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (a, b) => a + (b > 0 ? b : 0));
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < values.length; i++)
            if (values[i] > 0) ...[
              if (i > 0 && gap > 0) SizedBox(width: gap),
              Expanded(
                flex: math.max(1, (values[i] / total * 1000).round()),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(radius ?? height / 2),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
