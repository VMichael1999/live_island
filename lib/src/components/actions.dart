import '../core/bind.dart';
import '../core/json_util.dart';
import '../core/node.dart';
import 'visuals.dart';

/// Qué pasa al tocar un botón.
class LiveAction {
  const LiveAction._(this.type, {this.url, this.number});

  /// Abre un enlace profundo de la app.
  const LiveAction.deepLink(String url) : this._('deepLink', url: url);

  /// Llama a un número.
  const LiveAction.call(String number) : this._('call', number: number);

  /// Reenvía el id del botón a `LiveIsland.onAction` en Dart (por defecto).
  const LiveAction.custom() : this._('custom');

  final String type;
  final String? url;
  final String? number;

  Map<String, Object?> toJson() =>
      compact({'t': type, 'url': url, 'number': number});

  factory LiveAction.fromJson(Map<String, Object?> json) =>
      switch (json['t']) {
        'deepLink' => LiveAction.deepLink(json['url']! as String),
        'call' => LiveAction.call(json['number']! as String),
        _ => const LiveAction.custom(),
      };
}

final _idPattern = RegExp(r'^[a-z0-9_]+$');

void _checkId(String id) {
  if (!_idPattern.hasMatch(id)) {
    throw ArgumentError.value(
        id, 'id', 'Debe usar solo minúsculas, números y guiones bajos');
  }
}

/// Botón. Su [id] llega al callback `LiveIsland.onAction`.
class LiveButton extends LiveNode {
  LiveButton({required this.id, required this.label, this.icon, this.action}) {
    _checkId(id);
  }

  final String id;
  final String label;
  final LiveVisual? icon;
  final LiveAction? action;

  @override
  String get type => 'button';

  @override
  Iterable<LiveNode> get children => [if (icon != null) icon!];

  @override
  Map<String, Object?> toJson() => compact({
        't': 'button',
        'id': id,
        'label': label,
        'icon': icon?.toJson(),
        'action': action?.toJson(),
      });

  factory LiveButton.fromJson(Map<String, Object?> json) => LiveButton(
        id: json['id']! as String,
        label: json['label']! as String,
        icon: json['icon'] == null
            ? null
            : LiveVisual.fromJson(asMap(json['icon'], 'button.icon')),
        action: json['action'] == null
            ? null
            : LiveAction.fromJson(asMap(json['action'], 'button.action')),
      );
}

/// Interruptor ligado a un campo booleano del estado.
class LiveToggle extends LiveNode {
  LiveToggle({required this.id, required this.value, this.label, this.icon}) {
    _checkId(id);
  }

  final String id;
  final LiveBind value;
  final String? label;
  final LiveIcon? icon;

  @override
  String get type => 'toggle';

  @override
  Iterable<LiveNode> get children => [if (icon != null) icon!];

  @override
  Map<String, Object?> toJson() => compact({
        't': 'toggle',
        'id': id,
        'bind': value.field,
        'label': label,
        'icon': icon?.toJson(),
      });

  factory LiveToggle.fromJson(Map<String, Object?> json) => LiveToggle(
        id: json['id']! as String,
        value: LiveBind(json['bind']! as String),
        label: json['label'] as String?,
        icon: json['icon'] == null
            ? null
            : LiveIcon.fromJson(asMap(json['icon'], 'toggle.icon')),
      );
}
