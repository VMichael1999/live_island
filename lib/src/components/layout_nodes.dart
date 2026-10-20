import 'dart:ui' show Color;

import '../core/bind.dart';
import '../core/enums.dart';
import '../core/json_util.dart';
import '../core/node.dart';

/// Children laid out horizontally (HStack in SwiftUI).
class LiveRow extends LiveNode {
  const LiveRow(this.items, {this.gap, this.align});

  final List<LiveNode> items;
  final double? gap;
  final LiveAlign? align;

  @override
  String get type => 'row';

  @override
  Iterable<LiveNode> get children => items;

  @override
  Map<String, Object?> toJson() => compact({
    't': 'row',
    'c': [for (final c in items) c.toJson()],
    'gap': gap,
    'align': align?.name,
  });

  factory LiveRow.fromJson(Map<String, Object?> json) => LiveRow(
    LiveNode.listFromJson(json['c']),
    gap: (json['gap'] as num?)?.toDouble(),
    align:
        json['align'] == null
            ? null
            : enumByName(LiveAlign.values, json['align'], LiveAlign.center),
  );
}

/// Children laid out vertically (VStack in SwiftUI).
class LiveColumn extends LiveNode {
  const LiveColumn(this.items, {this.gap, this.align});

  final List<LiveNode> items;
  final double? gap;
  final LiveAlign? align;

  @override
  String get type => 'col';

  @override
  Iterable<LiveNode> get children => items;

  @override
  Map<String, Object?> toJson() => compact({
    't': 'col',
    'c': [for (final c in items) c.toJson()],
    'gap': gap,
    'align': align?.name,
  });

  factory LiveColumn.fromJson(Map<String, Object?> json) => LiveColumn(
    LiveNode.listFromJson(json['c']),
    gap: (json['gap'] as num?)?.toDouble(),
    align:
        json['align'] == null
            ? null
            : enumByName(LiveAlign.values, json['align'], LiveAlign.start),
  );
}

/// Children stacked one over another (ZStack in SwiftUI).
class LiveStack extends LiveNode {
  const LiveStack(this.items, {this.align});

  final List<LiveNode> items;
  final LiveAlign? align;

  @override
  String get type => 'stack';

  @override
  Iterable<LiveNode> get children => items;

  @override
  Map<String, Object?> toJson() => compact({
    't': 'stack',
    'c': [for (final c in items) c.toJson()],
    'align': align?.name,
  });

  factory LiveStack.fromJson(Map<String, Object?> json) => LiveStack(
    LiveNode.listFromJson(json['c']),
    align:
        json['align'] == null
            ? null
            : enumByName(LiveAlign.values, json['align'], LiveAlign.center),
  );
}

/// Space. Without [size] it is flexible and pushes its neighbors apart.
class LiveSpacer extends LiveNode {
  const LiveSpacer({this.size});

  final double? size;

  @override
  String get type => 'spacer';

  @override
  Map<String, Object?> toJson() => compact({'t': 'spacer', 'size': size});

  factory LiveSpacer.fromJson(Map<String, Object?> json) =>
      LiveSpacer(size: (json['size'] as num?)?.toDouble());
}

/// Margin around a child.
class LivePadding extends LiveNode {
  const LivePadding(
    this.child, {
    this.all,
    this.horizontal,
    this.vertical,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final LiveNode child;
  final double? all, horizontal, vertical, top, bottom, left, right;

  @override
  String get type => 'padding';

  @override
  Iterable<LiveNode> get children => [child];

  @override
  Map<String, Object?> toJson() => compact({
    't': 'padding',
    'child': child.toJson(),
    'all': all,
    'h': horizontal,
    'v': vertical,
    'top': top,
    'bottom': bottom,
    'left': left,
    'right': right,
  });

  factory LivePadding.fromJson(Map<String, Object?> json) {
    double? d(String k) => (json[k] as num?)?.toDouble();
    return LivePadding(
      LiveNode.fromJson(asMap(json['child'], 'padding.child')),
      all: d('all'),
      horizontal: d('h'),
      vertical: d('v'),
      top: d('top'),
      bottom: d('bottom'),
      left: d('left'),
      right: d('right'),
    );
  }
}

/// A box with size, corners and background (for example the 46 pt square
/// with a 22 % accent behind the expanded island's icon).
class LiveBox extends LiveNode {
  const LiveBox({
    this.child,
    this.size,
    this.radius,
    this.tint,
    this.color,
    this.border,
    this.borderWidth,
    this.glow,
  });

  final LiveNode? child;
  final double? size;
  final double? radius;

  /// Opacity (0 to 1) of the accent color used as the background.
  final double? tint;
  final Color? color;

  /// Border color (no border if missing).
  final Color? border;

  /// Border thickness in pt (1.5 by default).
  final double? borderWidth;

  /// Glow around the box: radius in pt of the halo, in the border's color
  /// (or the background's if there is no border).
  final double? glow;

  @override
  String get type => 'box';

  @override
  Iterable<LiveNode> get children => [if (child != null) child!];

  @override
  Map<String, Object?> toJson() => compact({
    't': 'box',
    'child': child?.toJson(),
    'size': size,
    'radius': radius,
    'tint': tint,
    'color': color == null ? null : colorToHex(color!),
    'border': border == null ? null : colorToHex(border!),
    'bw': borderWidth,
    'glow': glow,
  });

  factory LiveBox.fromJson(Map<String, Object?> json) => LiveBox(
    child:
        json['child'] == null
            ? null
            : LiveNode.fromJson(asMap(json['child'], 'box.child')),
    size: (json['size'] as num?)?.toDouble(),
    radius: (json['radius'] as num?)?.toDouble(),
    tint: (json['tint'] as num?)?.toDouble(),
    color:
        json['color'] == null ? null : colorFromHex(json['color']! as String),
    border:
        json['border'] == null ? null : colorFromHex(json['border']! as String),
    borderWidth: (json['bw'] as num?)?.toDouble(),
    glow: (json['glow'] as num?)?.toDouble(),
  );
}

/// Shows [then] if [when] holds (evaluated on the device); otherwise,
/// [otherwise].
class LiveIf extends LiveNode {
  const LiveIf(this.when, {required this.then, this.otherwise});

  final LiveCondition when;
  final LiveNode then;
  final LiveNode? otherwise;

  @override
  String get type => 'if';

  @override
  Iterable<LiveNode> get children => [then, if (otherwise != null) otherwise!];

  @override
  Map<String, Object?> toJson() => compact({
    't': 'if',
    'when': when.toJson(),
    'then': then.toJson(),
    'else': otherwise?.toJson(),
  });

  factory LiveIf.fromJson(Map<String, Object?> json) => LiveIf(
    LiveCondition.fromJson(asMap(json['when'], 'if.when')),
    then: LiveNode.fromJson(asMap(json['then'], 'if.then')),
    otherwise:
        json['else'] == null
            ? null
            : LiveNode.fromJson(asMap(json['else'], 'if.else')),
  );
}
