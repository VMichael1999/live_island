import 'json_util.dart';
import '../components/actions.dart';
import '../components/charts.dart';
import '../components/layout_nodes.dart';
import '../components/progress.dart';
import '../components/text.dart';
import '../components/visuals.dart';

/// A component of the design. In JSON it is an object with a `t` (type) field.
abstract class LiveNode {
  const LiveNode();

  /// Value of `t` in the JSON contract.
  String get type;

  Map<String, Object?> toJson();

  /// Direct children, to walk the tree (images, buttons, progress…).
  Iterable<LiveNode> get children => const [];

  /// This node and all its descendants, in order of appearance.
  Iterable<LiveNode> get descendants sync* {
    yield this;
    for (final c in children) {
      yield* c.descendants;
    }
  }

  /// Builds a node from the JSON contract (`layout.schema.json`).
  factory LiveNode.fromJson(Map<String, Object?> json) {
    final t = json['t'];
    switch (t) {
      case 'row':
        return LiveRow.fromJson(json);
      case 'col':
        return LiveColumn.fromJson(json);
      case 'stack':
        return LiveStack.fromJson(json);
      case 'spacer':
        return LiveSpacer.fromJson(json);
      case 'padding':
        return LivePadding.fromJson(json);
      case 'box':
        return LiveBox.fromJson(json);
      case 'if':
        return LiveIf.fromJson(json);
      case 'text':
      case 'countdown':
      case 'stopwatch':
      case 'relative':
        return LiveText.fromJson(json);
      case 'icon':
      case 'image':
      case 'avatar':
        return LiveVisual.fromJson(json);
      case 'bar':
      case 'ring':
        return LiveProgress.fromJson(json);
      case 'segments':
        return LiveSegments.fromJson(json);
      case 'split':
        return LiveSplitBar.fromJson(json);
      case 'spark':
        return LiveSparkline.fromJson(json);
      case 'gauge':
        return LiveGauge.fromJson(json);
      case 'path':
        return LiveFlightPath.fromJson(json);
      case 'metric':
        return LiveMetric.fromJson(json);
      case 'button':
        return LiveButton.fromJson(json);
      case 'toggle':
        return LiveToggle.fromJson(json);
    }
    throw FormatException('Unknown node type: $t');
  }

  /// Reads a list of child nodes (`"c": [...]`).
  static List<LiveNode> listFromJson(Object? raw) => [
    for (final c in (raw as List? ?? const []))
      LiveNode.fromJson(asMap(c, 'c')),
  ];
}
