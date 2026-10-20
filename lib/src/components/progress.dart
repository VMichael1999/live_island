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

/// Icon of a [LiveSegments] stage: [pending] while the stage has not been
/// reached and [reached] once it has. Useful, for example, for an order whose
/// steps turn from gray to colored.
class LiveStageIcon {
  const LiveStageIcon({required this.pending, required this.reached});

  final LiveImage pending, reached;

  Map<String, Object?> toJson() => {
    'pending': pending.toJson(),
    'reached': reached.toJson(),
  };

  factory LiveStageIcon.fromJson(Map<String, Object?> json) => LiveStageIcon(
    pending: LiveImage.fromJson(asMap(json['pending'], 'stageIcons.pending')),
    reached: LiveImage.fromJson(asMap(json['reached'], 'stageIcons.reached')),
  );
}

/// Style of a progress bar or ring. Everything is optional: what is not
/// specified takes its default value (the prototype's).
///
/// Android only honors [color], [pointColor], the tracker and the markers; the
/// thickness, spacing, corners and labels are decided by the system.
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
    this.dashed,
    this.labelSize,
    this.trackerSize,
    this.markers,
    this.glow,
    this.endMarker,
    this.markerLabels,
  });

  /// Bar thickness in pt (6 by default). In a ring, the stroke width (3).
  final double? height;

  /// Color of the completed part (the accent by default).
  final Color? color;

  /// Color of what remains.
  final Color? trackColor;

  /// Gap between segments (4 by default).
  final double? gap;

  /// Corners (half the thickness by default).
  final double? radius;

  /// Diameter of the stage dots (10 by default).
  final double? pointSize;

  /// Color of the completed dots (that of [color] by default).
  final Color? pointColor;

  /// Shape of the stage dots (a circle by default).
  final LivePointShape? pointShape;

  /// Draws what remains as a dashed stroke (solid by default).
  final bool? dashed;

  /// Size of the stage labels (11.5 by default).
  final double? labelSize;

  /// Diameter of the circle of the moving icon (26 by default).
  final double? trackerSize;

  /// Positions (0 to 1) of markers on the bar, with the shape of
  /// [pointShape]. The marker already passed and the next one use the color of
  /// the completed part; the others, that of what remains. Android ignores them.
  final List<double>? markers;

  /// Glow of the completed part (halo radius in pt): the "glowing cable".
  /// Android ignores it.
  final double? glow;

  /// Marker at the end of the bar, **attached** to it, with the moving icon on
  /// top when it reaches 100 %. It uses [pointSize] as its size and
  /// [LivePointShape.target] or [LivePointShape.targetSquare] as its shape.
  /// Android ignores it.
  final LivePointShape? endMarker;

  /// Text inside each marker of [markers] (in the same order, which must be
  /// ascending): for example `['1']` for a numbered stop. Android Live Update
  /// ignores it.
  final List<String>? markerLabels;

  bool get isEmpty =>
      height == null &&
      color == null &&
      trackColor == null &&
      gap == null &&
      radius == null &&
      pointSize == null &&
      pointColor == null &&
      pointShape == null &&
      dashed == null &&
      labelSize == null &&
      trackerSize == null &&
      markers == null &&
      glow == null &&
      endMarker == null &&
      markerLabels == null;

  LiveProgressStyle copyWith({
    double? height,
    Color? color,
    Color? trackColor,
    double? gap,
    double? radius,
    double? pointSize,
    Color? pointColor,
    LivePointShape? pointShape,
    bool? dashed,
    double? labelSize,
    double? trackerSize,
    List<double>? markers,
    double? glow,
    LivePointShape? endMarker,
    List<String>? markerLabels,
  }) => LiveProgressStyle(
    height: height ?? this.height,
    color: color ?? this.color,
    trackColor: trackColor ?? this.trackColor,
    gap: gap ?? this.gap,
    radius: radius ?? this.radius,
    pointSize: pointSize ?? this.pointSize,
    pointColor: pointColor ?? this.pointColor,
    pointShape: pointShape ?? this.pointShape,
    dashed: dashed ?? this.dashed,
    labelSize: labelSize ?? this.labelSize,
    trackerSize: trackerSize ?? this.trackerSize,
    markers: markers ?? this.markers,
    glow: glow ?? this.glow,
    endMarker: endMarker ?? this.endMarker,
    markerLabels: markerLabels ?? this.markerLabels,
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
    'dashed': dashed == true ? true : null,
    'labelSize': labelSize,
    'trackerSize': trackerSize,
    'markers': markers,
    'glow': glow,
    'endMarker': endMarker?.name,
    'markerLabels': markerLabels,
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
      dashed: json['dashed'] == true ? true : null,
      labelSize: d('labelSize'),
      trackerSize: d('trackerSize'),
      markers:
          [
            for (final m in (json['markers'] as List? ?? const []))
              (m as num).toDouble(),
          ].nullIfEmpty,
      glow: d('glow'),
      endMarker:
          json['endMarker'] == null
              ? null
              : LivePointShape.values.byName(json['endMarker']! as String),
      markerLabels:
          [
            for (final l in (json['markerLabels'] as List? ?? const []))
              l as String,
          ].nullIfEmpty,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LiveProgressStyle && '${other.toJson()}' == '${toJson()}';

  @override
  int get hashCode => '${toJson()}'.hashCode;
}

extension<T> on List<T> {
  List<T>? get nullIfEmpty => isEmpty ? null : this;
}

LiveProgressStyle? progressStyleFromJson(Object? raw) =>
    raw == null ? null : LiveProgressStyle.fromJson(asMap(raw, 'style'));

Map<String, Object?>? progressStyleToJson(LiveProgressStyle? s) =>
    s == null || s.isEmpty ? null : s.toJson();

/// Continuous progress bar or ring. The value is a number from 0 to 1 read
/// from the [value] field of the state.
class LiveProgress extends LiveNode {
  /// Bar with a moving icon ([tracker]) and icons at the ends
  /// ([startIcon], [endIcon]). Everything is optional: with no [tracker] or
  /// icons only the bar remains. [style] changes thickness, colors, corners.
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

  /// Ring. On Android it is shown as a bar. [child] goes inside the ring.
  /// [style] changes the stroke width (`height`) and the colors.
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
    'style': progressStyleToJson(style),
    'tracker': tracker?.toJson(),
    'start': startIcon?.toJson(),
    'end': endIcon?.toJson(),
    'child': child?.toJson(),
    'size': size,
  });

  factory LiveProgress.fromJson(Map<String, Object?> json) {
    final value = LiveBind(json['bind']! as String);
    final style = progressStyleFromJson(json['style']);
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

/// Bar by stages: `n` labels give `n - 1` segments, with optional dots.
///
/// Everything is optional: [points] (a dot per stage), [showLabels] (the
/// labels), [tracker] (the moving icon or image) and the [startIcon] and
/// [endIcon] markers. [style] changes thickness, colors, corners, spacing
/// and sizes.
class LiveSegments extends LiveNode {
  LiveSegments({
    required this.value,
    required this.labels,
    this.points = false,
    this.showLabels = true,
    LiveTrackerSource? tracker,
    this.startIcon,
    this.endIcon,
    this.stageIcons,
    this.style,
  }) : tracker = tracker?.asTracker();

  final LiveBind value;

  /// One icon per stage (one for each element of [labels]), instead of the
  /// dots: gray until the stage is reached and colored once it is. Its size is
  /// `style.pointSize`; the segments end before each icon according to
  /// `style.gap`. Android Live Update ignores it.
  final List<LiveStageIcon>? stageIcons;

  /// One label per stage (at least two). Even if they are not shown
  /// ([showLabels] set to `false`) they define how many segments there are.
  final List<String> labels;
  final bool points;

  /// Shows the stage labels.
  final bool showLabels;
  final LiveTracker? tracker;
  final LiveVisual? startIcon;
  final LiveVisual? endIcon;
  final LiveProgressStyle? style;

  @override
  String get type => 'segments';

  @override
  Iterable<LiveNode> get children => [
    ..._progressChildren(tracker, startIcon, endIcon),
    for (final s in stageIcons ?? const <LiveStageIcon>[]) ...[
      s.pending,
      s.reached,
    ],
  ];

  @override
  Map<String, Object?> toJson() => compact({
    't': 'segments',
    'bind': value.field,
    'labels': labels,
    'points': points,
    'showLabels': showLabels ? null : false,
    'stageIcons':
        stageIcons == null ? null : [for (final s in stageIcons!) s.toJson()],
    'style': progressStyleToJson(style),
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
    stageIcons:
        [
          for (final s in (json['stageIcons'] as List? ?? const []))
            LiveStageIcon.fromJson(asMap(s, 'segments.stageIcons')),
        ].nullIfEmpty,
    style: progressStyleFromJson(json['style']),
  );
}

/// A live numeric value with a unit and a label (`MetricStyle` on Android 17).
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
