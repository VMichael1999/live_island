import 'dart:ui' show Color;

import '../core/bind.dart';
import '../core/enums.dart';
import '../core/json_util.dart';
import '../core/node.dart';

/// Hijos en horizontal (HStack en SwiftUI).
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

/// Hijos en vertical (VStack en SwiftUI).
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

/// Hijos uno encima de otro (ZStack en SwiftUI).
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

/// Espacio. Sin [size] es flexible y empuja a los vecinos.
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

/// Margen alrededor de un hijo.
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

/// Caja con tamaño, esquinas y fondo (por ejemplo el cuadro de 46 pt con
/// acento al 22 % detrás del ícono de la isla expandida).
class LiveBox extends LiveNode {
  const LiveBox({this.child, this.size, this.radius, this.tint, this.color});

  final LiveNode? child;
  final double? size;
  final double? radius;

  /// Opacidad (0 a 1) del color de acento usada como fondo.
  final double? tint;
  final Color? color;

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
  );
}

/// Muestra [then] si se cumple [when] (se evalúa en el dispositivo); si no,
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
