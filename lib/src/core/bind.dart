/// Una fuente de texto que Android puede mostrar (título y texto de la
/// notificación): un campo del estado, un literal o una plantilla.
abstract interface class LiveTextSource {
  Map<String, Object?> toAndroidTextJson();
}

/// Enlace a un campo del estado. Los nombres los elige quien usa el paquete.
class LiveBind implements LiveTextSource {
  const LiveBind(this.field);

  final String field;

  LiveCondition equals(Object? value) => LiveCondition(field, 'eq', value);
  LiveCondition notEquals(Object? value) => LiveCondition(field, 'neq', value);
  LiveCondition greaterThan(num value) => LiveCondition(field, 'gt', value);
  LiveCondition greaterOrEqual(num value) => LiveCondition(field, 'gte', value);
  LiveCondition lessThan(num value) => LiveCondition(field, 'lt', value);
  LiveCondition lessOrEqual(num value) => LiveCondition(field, 'lte', value);
  LiveCondition get isTrue => LiveCondition(field, 'truthy', true);

  @override
  Map<String, Object?> toAndroidTextJson() => {'bind': field};

  @override
  bool operator ==(Object other) => other is LiveBind && other.field == field;

  @override
  int get hashCode => field.hashCode;

  @override
  String toString() => "bind('$field')";
}

/// `bind('etapa')`: enlaza con el campo `etapa` del estado.
LiveBind bind(String field) => LiveBind(field);

/// Condición de un `LiveIf`: un campo y exactamente un operador.
class LiveCondition {
  const LiveCondition(this.field, this.op, this.value);

  static const operators = {'eq', 'neq', 'gt', 'gte', 'lt', 'lte', 'truthy'};

  final String field;
  final String op;
  final Object? value;

  Map<String, Object?> toJson() => {'bind': field, op: value};

  factory LiveCondition.fromJson(Map<String, Object?> json) {
    final ops = json.keys.where(operators.contains).toList();
    final field = json['bind'];
    if (field is! String || ops.length != 1) {
      throw const FormatException(
          'Una condición lleva "bind" y exactamente un operador');
    }
    return LiveCondition(field, ops.single, json[ops.single]);
  }

  /// Evalúa la condición contra [state].
  bool evaluate(Map<String, Object?> state) {
    final v = state[field];
    switch (op) {
      case 'eq':
        return v == value;
      case 'neq':
        return v != value;
      case 'truthy':
        return v != null && v != false && v != 0 && v != '';
      default:
        if (v is! num || value is! num) return false;
        final a = v, b = value! as num;
        return switch (op) {
          'gt' => a > b,
          'gte' => a >= b,
          'lt' => a < b,
          _ => a <= b,
        };
    }
  }

  Map<String, Object?> get _key => toJson();

  @override
  bool operator ==(Object other) =>
      other is LiveCondition && '${other._key}' == '$_key';

  @override
  int get hashCode => '$_key'.hashCode;
}

/// Plantilla `{campo}`: sustituye cada campo por su valor en [state].
String formatTemplate(String fmt, Map<String, Object?> state) =>
    fmt.replaceAllMapped(
      RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}'),
      (m) => '${state[m[1]] ?? ''}',
    );
