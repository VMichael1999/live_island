import '../core/bind.dart';
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

/// Barra de progreso continua o anillo. El valor es un número de 0 a 1 que
/// se lee del campo [value] del estado.
class LiveProgress extends LiveNode {
  /// Barra con ícono que avanza ([tracker]) e íconos en los extremos.
  LiveProgress.bar({
    required this.value,
    LiveTrackerSource? tracker,
    this.startIcon,
    this.endIcon,
  }) : isRing = false,
       tracker = tracker?.asTracker(),
       child = null,
       size = null;

  /// Anillo. En Android se muestra como barra. [child] va dentro del anillo.
  const LiveProgress.ring({required this.value, this.child, this.size})
    : isRing = true,
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
    'tracker': tracker?.toJson(),
    'start': startIcon?.toJson(),
    'end': endIcon?.toJson(),
    'child': child?.toJson(),
    'size': size,
  });

  factory LiveProgress.fromJson(Map<String, Object?> json) {
    final value = LiveBind(json['bind']! as String);
    if (json['t'] == 'ring') {
      return LiveProgress.ring(
        value: value,
        child:
            json['child'] == null
                ? null
                : LiveNode.fromJson(asMap(json['child'], 'ring.child')),
        size: (json['size'] as num?)?.toDouble(),
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
    );
  }
}

/// Barra por etapas: `n` etiquetas dan `n - 1` tramos, con puntos opcionales.
class LiveSegments extends LiveNode {
  LiveSegments({
    required this.value,
    required this.labels,
    this.points = false,
    LiveTrackerSource? tracker,
    this.startIcon,
    this.endIcon,
  }) : tracker = tracker?.asTracker();

  final LiveBind value;

  /// Una etiqueta por etapa (mínimo dos).
  final List<String> labels;
  final bool points;
  final LiveTracker? tracker;
  final LiveVisual? startIcon;
  final LiveVisual? endIcon;

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
    'tracker': tracker?.toJson(),
    'start': startIcon?.toJson(),
    'end': endIcon?.toJson(),
  });

  factory LiveSegments.fromJson(Map<String, Object?> json) => LiveSegments(
    value: LiveBind(json['bind']! as String),
    labels: [for (final l in json['labels']! as List) l as String],
    points: json['points'] == true,
    tracker:
        json['tracker'] == null
            ? null
            : LiveTracker.fromJson(asMap(json['tracker'], 'segments.tracker')),
    startIcon: _endFromJson(json['start'], 'segments.start'),
    endIcon: _endFromJson(json['end'], 'segments.end'),
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
