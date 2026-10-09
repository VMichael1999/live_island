import 'dart:ui' show Color;

import '../core/bind.dart';
import '../core/enums.dart';
import '../core/json_util.dart';
import '../core/node.dart';
import 'visuals.dart';

LiveVisual? _endFromJson(Object? raw, String where) =>
    raw == null ? null : LiveVisual.fromJson(asMap(raw, where));

Iterable<LiveNode> _progressChildren(
  LiveTracker? tracker,
  LiveVisual? start,
  LiveVisual? end,
) => [
  if (tracker != null) tracker.visual,
  if (start != null) start,
  if (end != null) end,
];

/// Estilo de una barra o un anillo de progreso. Todo es opcional: lo que no se
/// indica toma su valor por defecto (los del prototipo).
///
/// Android solo respeta [color], [pointColor], el tracker y los marcadores; el
/// grosor, el espacio, las esquinas y las etiquetas los decide el sistema.
class LiveProgressStyle {
  const LiveProgressStyle({
    this.height,
    this.color,
    this.trackColor,
    this.gap,
    this.radius,
    this.pointSize,
    this.pointColor,
    this.pointShape,
    this.labelSize,
    this.trackerSize,
  });

  /// Grosor de la barra en pt (por defecto 6). En un anillo, el ancho del trazo (3).
  final double? height;

  /// Color de lo avanzado (por defecto el acento).
  final Color? color;

  /// Color de lo que falta.
  final Color? trackColor;

  /// Separación entre tramos (por defecto 4).
  final double? gap;

  /// Esquinas (por defecto la mitad del grosor).
  final double? radius;

  /// Diámetro de los puntos de etapa (por defecto 10).
  final double? pointSize;

  /// Color de los puntos completados (por defecto el de [color]).
  final Color? pointColor;

  /// Forma de los puntos de etapa (por defecto círculo).
  final LivePointShape? pointShape;

  /// Tamaño de las etiquetas de etapas (por defecto 11,5).
  final double? labelSize;

  /// Diámetro del círculo del ícono que avanza (por defecto 26).
  final double? trackerSize;

  bool get isEmpty =>
      height == null &&
      color == null &&
      trackColor == null &&
      gap == null &&
      radius == null &&
      pointSize == null &&
      pointColor == null &&
      pointShape == null &&
      labelSize == null &&
      trackerSize == null;

  LiveProgressStyle copyWith({
    double? height,
    Color? color,
    Color? trackColor,
    double? gap,
    double? radius,
    double? pointSize,
    Color? pointColor,
    LivePointShape? pointShape,
    double? labelSize,
    double? trackerSize,
  }) => LiveProgressStyle(
    height: height ?? this.height,
    color: color ?? this.color,
    trackColor: trackColor ?? this.trackColor,
    gap: gap ?? this.gap,
    radius: radius ?? this.radius,
    pointSize: pointSize ?? this.pointSize,
    pointColor: pointColor ?? this.pointColor,
    pointShape: pointShape ?? this.pointShape,
    labelSize: labelSize ?? this.labelSize,
    trackerSize: trackerSize ?? this.trackerSize,
  );

  Map<String, Object?> toJson() => compact({
    'h': height,
    'color': color == null ? null : colorToHex(color!),
    'trackColor': trackColor == null ? null : colorToHex(trackColor!),
    'gap': gap,
    'radius': radius,
    'pointSize': pointSize,
    'pointColor': pointColor == null ? null : colorToHex(pointColor!),
    'pointShape': pointShape?.name,
    'labelSize': labelSize,
    'trackerSize': trackerSize,
  });

  factory LiveProgressStyle.fromJson(Map<String, Object?> json) {
    double? d(String k) => (json[k] as num?)?.toDouble();
    Color? c(String k) =>
        json[k] == null ? null : colorFromHex(json[k]! as String);
    return LiveProgressStyle(
      height: d('h'),
      color: c('color'),
      trackColor: c('trackColor'),
      gap: d('gap'),
      radius: d('radius'),
      pointSize: d('pointSize'),
      pointColor: c('pointColor'),
      pointShape:
          json['pointShape'] == null
              ? null
              : LivePointShape.values.byName(json['pointShape']! as String),
      labelSize: d('labelSize'),
      trackerSize: d('trackerSize'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LiveProgressStyle && '${other.toJson()}' == '${toJson()}';

  @override
  int get hashCode => '${toJson()}'.hashCode;
}

LiveProgressStyle? _styleFromJson(Object? raw) =>
    raw == null ? null : LiveProgressStyle.fromJson(asMap(raw, 'style'));

Map<String, Object?>? _styleJson(LiveProgressStyle? s) =>
    s == null || s.isEmpty ? null : s.toJson();

/// Barra de progreso continua o anillo. El valor es un número de 0 a 1 que
/// se lee del campo [value] del estado.
class LiveProgress extends LiveNode {
  /// Barra con ícono que avanza ([tracker]) e íconos en los extremos
  /// ([startIcon], [endIcon]). Todo es opcional: sin [tracker] ni íconos queda
  /// solo la barra. [style] cambia grosor, colores, esquinas y espacio.
  LiveProgress.bar({
    required this.value,
    LiveTrackerSource? tracker,
    this.startIcon,
    this.endIcon,
    this.style,
  }) : isRing = false,
       tracker = tracker?.asTracker(),
       child = null,
       size = null;

  /// Anillo. En Android se muestra como barra. [child] va dentro del anillo.
  /// [style] cambia el ancho del trazo (`height`) y los colores.
  const LiveProgress.ring({
    required this.value,
    this.child,
    this.size,
    this.style,
  }) : isRing = true,
       tracker = null,
       startIcon = null,
       endIcon = null;

  final LiveBind value;
  final bool isRing;
  final LiveTracker? tracker;
  final LiveVisual? startIcon;
  final LiveVisual? endIcon;
  final LiveNode? child;
  final double? size;
  final LiveProgressStyle? style;

  @override
  String get type => isRing ? 'ring' : 'bar';

  @override
  Iterable<LiveNode> get children =>
      isRing
          ? [if (child != null) child!]
          : _progressChildren(tracker, startIcon, endIcon);

  @override
  Map<String, Object?> toJson() => compact({
    't': type,
    'bind': value.field,
    'style': _styleJson(style),
    'tracker': tracker?.toJson(),
    'start': startIcon?.toJson(),
    'end': endIcon?.toJson(),
    'child': child?.toJson(),
    'size': size,
  });

  factory LiveProgress.fromJson(Map<String, Object?> json) {
    final value = LiveBind(json['bind']! as String);
    final style = _styleFromJson(json['style']);
    if (json['t'] == 'ring') {
      return LiveProgress.ring(
        value: value,
        child:
            json['child'] == null
                ? null
                : LiveNode.fromJson(asMap(json['child'], 'ring.child')),
        size: (json['size'] as num?)?.toDouble(),
        style: style,
      );
    }
    return LiveProgress.bar(
      value: value,
      tracker:
          json['tracker'] == null
              ? null
              : LiveTracker.fromJson(asMap(json['tracker'], 'bar.tracker')),
      startIcon: _endFromJson(json['start'], 'bar.start'),
      endIcon: _endFromJson(json['end'], 'bar.end'),
      style: style,
    );
  }
}

/// Barra por etapas: `n` etiquetas dan `n - 1` tramos, con puntos opcionales.
///
/// Todo es opcional: [points] (un punto por etapa), [showLabels] (las
/// etiquetas), [tracker] (el ícono o imagen que avanza) y los marcadores
/// [startIcon] y [endIcon]. [style] cambia grosor, colores, esquinas, espacio
/// y tamaños.
class LiveSegments extends LiveNode {
  LiveSegments({
    required this.value,
    required this.labels,
    this.points = false,
    this.showLabels = true,
    LiveTrackerSource? tracker,
    this.startIcon,
    this.endIcon,
    this.style,
  }) : tracker = tracker?.asTracker();

  final LiveBind value;

  /// Una etiqueta por etapa (mínimo dos). Aunque no se muestren ([showLabels]
  /// en `false`) definen cuántos tramos hay.
  final List<String> labels;
  final bool points;

  /// Muestra las etiquetas de las etapas.
  final bool showLabels;
  final LiveTracker? tracker;
  final LiveVisual? startIcon;
  final LiveVisual? endIcon;
  final LiveProgressStyle? style;

  @override
  String get type => 'segments';

  @override
  Iterable<LiveNode> get children =>
      _progressChildren(tracker, startIcon, endIcon);

  @override
  Map<String, Object?> toJson() => compact({
    't': 'segments',
    'bind': value.field,
    'labels': labels,
    'points': points,
    'showLabels': showLabels ? null : false,
    'style': _styleJson(style),
    'tracker': tracker?.toJson(),
    'start': startIcon?.toJson(),
    'end': endIcon?.toJson(),
  });

  factory LiveSegments.fromJson(Map<String, Object?> json) => LiveSegments(
    value: LiveBind(json['bind']! as String),
    labels: [for (final l in json['labels']! as List) l as String],
    points: json['points'] == true,
    showLabels: json['showLabels'] != false,
    tracker:
        json['tracker'] == null
            ? null
            : LiveTracker.fromJson(asMap(json['tracker'], 'segments.tracker')),
    startIcon: _endFromJson(json['start'], 'segments.start'),
    endIcon: _endFromJson(json['end'], 'segments.end'),
    style: _styleFromJson(json['style']),
  );
}

/// Un dato numérico en vivo con unidad y etiqueta (`MetricStyle` en Android 17).
class LiveMetric extends LiveNode {
  const LiveMetric({required this.value, this.unit, this.label});

  final LiveBind value;
  final String? unit;
  final String? label;

  @override
  String get type => 'metric';

  @override
  Map<String, Object?> toJson() => compact({
    't': 'metric',
    'bind': value.field,
    'unit': unit,
    'label': label,
  });

  factory LiveMetric.fromJson(Map<String, Object?> json) => LiveMetric(
    value: LiveBind(json['bind']! as String),
    unit: json['unit'] as String?,
    label: json['label'] as String?,
  );
}
