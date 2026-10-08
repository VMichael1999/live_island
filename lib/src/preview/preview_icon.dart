import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import 'preview_config.dart';
import 'preview_symbols.dart';

/// Ícono de contorno (trazo redondeado, viewBox 24) de los símbolos incluidos.
class LiveSymbolIcon extends StatelessWidget {
  const LiveSymbolIcon(
    this.symbol, {
    super.key,
    required this.size,
    required this.color,
    this.strokeWidth = 2.2,
    this.fallback,
  });

  /// Nombre de SF Symbol o nombre del archivo de Android en minúsculas.
  final String symbol;
  final double size;
  final Color color;
  final double strokeWidth;
  final LiveSymbolBuilder? fallback;

  static bool has(String symbol) => kPreviewSymbols.containsKey(symbol);

  @override
  Widget build(BuildContext context) {
    final d = kPreviewSymbols[symbol];
    if (d == null) {
      return fallback?.call(symbol, size, color) ??
          _MissingSymbol(size: size, color: color);
    }
    return CustomPaint(
      size: Size.square(size),
      painter: _SymbolPainter(_pathFor(d), color, strokeWidth),
    );
  }
}

final _cache = <String, Path>{};
Path _pathFor(String d) => _cache.putIfAbsent(d, () => parseSvgPathData(d));

class _SymbolPainter extends CustomPainter {
  _SymbolPainter(this.path, this.color, this.strokeWidth);

  final Path path;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SymbolPainter old) =>
      old.path != path || old.color != color || old.strokeWidth != strokeWidth;
}

class _MissingSymbol extends StatelessWidget {
  const _MissingSymbol({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(size * .22),
      ),
    ),
  );
}
