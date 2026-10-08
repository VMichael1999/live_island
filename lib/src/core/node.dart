import 'json_util.dart';
import '../components/actions.dart';
import '../components/layout_nodes.dart';
import '../components/progress.dart';
import '../components/text.dart';
import '../components/visuals.dart';

/// Un componente del diseño. En JSON es un objeto con el campo `t` (tipo).
abstract class LiveNode {
  const LiveNode();

  /// Valor de `t` en el contrato JSON.
  String get type;

  Map<String, Object?> toJson();

  /// Hijos directos, para recorrer el árbol (imágenes, botones, progreso…).
  Iterable<LiveNode> get children => const [];

  /// Este nodo y todos sus descendientes, en orden de aparición.
  Iterable<LiveNode> get descendants sync* {
    yield this;
    for (final c in children) {
      yield* c.descendants;
    }
  }

  /// Construye un nodo desde el contrato JSON (`layout.schema.json`).
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
      case 'metric':
        return LiveMetric.fromJson(json);
      case 'button':
        return LiveButton.fromJson(json);
      case 'toggle':
        return LiveToggle.fromJson(json);
    }
    throw FormatException('Tipo de nodo desconocido: $t');
  }

  /// Lee una lista de nodos hijos (`"c": [...]`).
  static List<LiveNode> listFromJson(Object? raw) => [
        for (final c in (raw as List? ?? const []))
          LiveNode.fromJson(asMap(c, 'c')),
      ];
}
