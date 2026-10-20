import 'dart:ui' show Color;

import '../core/bind.dart';
import '../core/json_util.dart';
import '../core/node.dart';
import 'progress.dart';
import 'visuals.dart';

/// Converts a series of numbers to the text that travels in the state
/// (`"10,12.5,11"`), which is what [LiveSparkline] reads.
///
/// ```dart
/// LiveIsland.update(id, {'series': liveSeries([212, 214.5, 213.2, 219])});
/// ```
String liveSeries(Iterable<num> values) =>
    [for (final v in values) v == v.roundToDouble() ? v.toInt() : v].join(',');

/// Reads a series written with [liveSeries] (it also accepts a list).
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

/// Small line chart ("sparkline") for prices, heart rate, speed…
///
/// The state stores the series as text with [liveSeries]. It is omitted on
/// Android: a notification cannot draw a chart.
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

  /// State field with the series (`"10,12.5,11"`).
  final LiveBind series;
  final double height;

  /// Color of the line. The card's accent by default.
  final Color? color;

  /// Fills the area under the line with a soft gradient.
  final bool fill;
  final double strokeWidth;

  /// Dot on the last value.
  final bool dot;

  /// Limits of the vertical axis. Without them they adjust to the series.
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

/// Arc gauge: part of a ring (half a turn by default) with a moving dot.
/// Useful for an orbit, a parking meter, a battery…
///
/// On Android it is shown as a progress bar.
class LiveGauge extends LiveNode {
  const LiveGauge({
    required this.value,
    this.size = 96,
    this.sweep = 180,
    this.knob = true,
    this.style,
    this.child,
  });

  /// Numeric field 0..1.
  final LiveBind value;

  /// Width of the gauge in pt.
  final double size;

  /// Degrees the arc spans (from 90 to 360). 180 is a semicircle.
  final double sweep;

  /// Dot at the end of the completed part.
  final bool knob;

  /// Color, background color, thickness (`height`) and dashed shape.
  final LiveProgressStyle? style;

  /// Content in the center of the arc.
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

/// Curved route between two points with an icon moving along it: a flight's
/// airplane, a package on its way…
///
/// On Android it is shown as a progress bar with the same icon.
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

  /// Numeric field 0..1.
  final LiveBind value;
  final double height;

  /// How much the route arches (0 = straight, 1 = very curved).
  final double curve;

  /// Icon that moves along the route.
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

/// A segment of a [LiveSplitBar]: its value (a numeric state field) and its
/// color.
class LiveSplitPart {
  const LiveSplitPart(this.value, this.color);

  /// Numeric state field; the segments are split in proportion to their value.
  final LiveBind value;
  final Color color;

  Map<String, Object?> toJson() => {
    'bind': value.field,
    'color': colorToHex(color),
  };

  factory LiveSplitPart.fromJson(Map<String, Object?> json) => LiveSplitPart(
    LiveBind(json['bind']! as String),
    colorFromHex(json['color']! as String),
  );
}

/// Bar split into segments of different colors, laid out in proportion to
/// their values: the fare and the tip, what was spent and what is left…
///
/// Android omits it (a notification cannot draw it).
class LiveSplitBar extends LiveNode {
  const LiveSplitBar(this.parts, {this.height = 10, this.gap = 3, this.radius});

  final List<LiveSplitPart> parts;

  /// Thickness in pt.
  final double height;

  /// Gap between segments in pt.
  final double gap;

  /// Corners (half the thickness by default).
  final double? radius;

  @override
  String get type => 'split';

  @override
  Map<String, Object?> toJson() => compact({
    't': 'split',
    'parts': [for (final p in parts) p.toJson()],
    'h': height == 10 ? null : height,
    'gap': gap == 3 ? null : gap,
    'radius': radius,
  });

  factory LiveSplitBar.fromJson(Map<String, Object?> json) => LiveSplitBar(
    [
      for (final p in (json['parts']! as List))
        LiveSplitPart.fromJson(asMap(p, 'split.parts')),
    ],
    height: (json['h'] as num?)?.toDouble() ?? 10,
    gap: (json['gap'] as num?)?.toDouble() ?? 3,
    radius: (json['radius'] as num?)?.toDouble(),
  );
}
