import 'dart:ui' show Color;

import '../core/bind.dart';
import '../core/json_util.dart';
import '../core/node.dart';
import 'progress.dart';
import 'visuals.dart';

/// Convierte una serie de números al texto que viaja en el estado
/// (`"10,12.5,11"`), que es lo que lee [LiveSparkline].
///
/// ```dart
/// LiveIsland.update(id, {'serie': liveSeries([212, 214.5, 213.2, 219])});
/// ```
String liveSeries(Iterable<num> values) =>
    [for (final v in values) v == v.roundToDouble() ? v.toInt() : v].join(',');

/// Lee una serie escrita con [liveSeries] (también acepta una lista).
List<double> parseLiveSeries(Object? raw) {
  if (raw is List) {
    return [
      for (final v in raw)
        if (v is num) v.toDouble(),
    ];
  }
  if (raw is! String) return const [];
  return [
    for (final p in raw.split(','))
      if (double.tryParse(p.trim()) case final d?) d,
  ];
}

/// Gráfica de línea pequeña ("sparkline") para precios, pulso, velocidad…
///
/// El estado guarda la serie como texto con [liveSeries]. En Android se omite:
/// una notificación no puede dibujar una gráfica.
class LiveSparkline extends LiveNode {
  const LiveSparkline({
    required this.series,
    this.height = 36,
    this.color,
    this.fill = true,
    this.strokeWidth = 2,
    this.dot = true,
    this.min,
    this.max,
  });

  /// Campo del estado con la serie (`"10,12.5,11"`).
  final LiveBind series;
  final double height;

  /// Color de la línea. Por defecto el acento de la tarjeta.
  final Color? color;

  /// Rellena el área bajo la línea con un degradado suave.
  final bool fill;
  final double strokeWidth;

  /// Punto en el último valor.
  final bool dot;

  /// Límites del eje vertical. Sin ellos se ajustan a la serie.
  final double? min;
  final double? max;

  @override
  String get type => 'spark';

  @override
  Map<String, Object?> toJson() => compact({
    't': 'spark',
    'bind': series.field,
    'h': height == 36 ? null : height,
    'color': color == null ? null : colorToHex(color!),
    'fill': fill ? null : false,
    'w': strokeWidth == 2 ? null : strokeWidth,
    'dot': dot ? null : false,
    'min': min,
    'max': max,
  });

  factory LiveSparkline.fromJson(Map<String, Object?> json) => LiveSparkline(
    series: LiveBind(json['bind']! as String),
    height: (json['h'] as num?)?.toDouble() ?? 36,
    color:
        json['color'] == null ? null : colorFromHex(json['color']! as String),
    fill: json['fill'] != false,
    strokeWidth: (json['w'] as num?)?.toDouble() ?? 2,
    dot: json['dot'] != false,
    min: (json['min'] as num?)?.toDouble(),
    max: (json['max'] as num?)?.toDouble(),
  );
}

/// Medidor de arco: parte de un anillo (por defecto media vuelta) con un
/// punto que avanza. Sirve para una órbita, un parquímetro, una batería…
///
/// En Android se muestra como barra de progreso.
class LiveGauge extends LiveNode {
  const LiveGauge({
    required this.value,
    this.size = 96,
    this.sweep = 180,
    this.knob = true,
    this.style,
    this.child,
  });

  /// Campo numérico 0..1.
  final LiveBind value;

  /// Ancho del medidor en pt.
  final double size;

  /// Grados que abarca el arco (de 90 a 360). 180 es un semicírculo.
  final double sweep;

  /// Punto en el extremo de lo avanzado.
  final bool knob;

  /// Color, color del fondo, grosor (`height`) y forma discontinua.
  final LiveProgressStyle? style;

  /// Contenido en el centro del arco.
  final LiveNode? child;

  @override
  String get type => 'gauge';

  @override
  Iterable<LiveNode> get children => [if (child != null) child!];

  @override
  Map<String, Object?> toJson() => compact({
    't': 'gauge',
    'bind': value.field,
    'size': size == 96 ? null : size,
    'sweep': sweep == 180 ? null : sweep,
    'knob': knob ? null : false,
    'style': progressStyleToJson(style),
    'child': child?.toJson(),
  });

  factory LiveGauge.fromJson(Map<String, Object?> json) => LiveGauge(
    value: LiveBind(json['bind']! as String),
    size: (json['size'] as num?)?.toDouble() ?? 96,
    sweep: (json['sweep'] as num?)?.toDouble() ?? 180,
    knob: json['knob'] != false,
    style: progressStyleFromJson(json['style']),
    child:
        json['child'] == null
            ? null
            : LiveNode.fromJson(asMap(json['child'], 'gauge.child')),
  );
}

/// Ruta curva entre dos puntos con un ícono que avanza por ella: el avión de
/// un vuelo, un paquete en camino…
///
/// En Android se muestra como barra de progreso con el mismo ícono.
class LiveFlightPath extends LiveNode {
  LiveFlightPath({
    required this.value,
    this.height = 44,
    this.curve = .55,
    LiveTrackerSource? tracker,
    this.startIcon,
    this.endIcon,
    this.style,
  }) : tracker = tracker?.asTracker();

  /// Campo numérico 0..1.
  final LiveBind value;
  final double height;

  /// Cuánto se arquea la ruta (0 = recta, 1 = muy curva).
  final double curve;

  /// Ícono que avanza por la ruta.
  final LiveTracker? tracker;
  final LiveVisual? startIcon;
  final LiveVisual? endIcon;
  final LiveProgressStyle? style;

  @override
  String get type => 'path';

  @override
  Iterable<LiveNode> get children => [
    if (tracker != null) tracker!.visual,
    if (startIcon != null) startIcon!,
    if (endIcon != null) endIcon!,
  ];

  @override
  Map<String, Object?> toJson() => compact({
    't': 'path',
    'bind': value.field,
    'h': height == 44 ? null : height,
    'curve': curve == .55 ? null : curve,
    'style': progressStyleToJson(style),
    'tracker': tracker?.toJson(),
    'start': startIcon?.toJson(),
    'end': endIcon?.toJson(),
  });

  factory LiveFlightPath.fromJson(Map<String, Object?> json) => LiveFlightPath(
    value: LiveBind(json['bind']! as String),
    height: (json['h'] as num?)?.toDouble() ?? 44,
    curve: (json['curve'] as num?)?.toDouble() ?? .55,
    tracker:
        json['tracker'] == null
            ? null
            : LiveTracker.fromJson(asMap(json['tracker'], 'path.tracker')),
    startIcon:
        json['start'] == null
            ? null
            : LiveVisual.fromJson(asMap(json['start'], 'path.start')),
    endIcon:
        json['end'] == null
            ? null
            : LiveVisual.fromJson(asMap(json['end'], 'path.end')),
    style: progressStyleFromJson(json['style']),
  );
}
