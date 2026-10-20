/// Una fuente de texto que Android puede mostrar (título y texto de la
/// notificación): un campo del estado, un literal o una plantilla.
abstract interface class LiveTextSource {
  Map<String, Object?> toAndroidTextJson();
}

/// Enlace a un campo del estado. Los nombres los elige quien usa el paquete.
class LiveBind implements LiveTextSource {
  const LiveBind(this.field);

  /// El estado «desactualizado»: pasa a `true` cuando llega la fecha de
  /// `staleAfter` y el sistema vuelve a dibujar la actividad, sin push ni
  /// actualización. Úsalo en un `LiveIf` para mostrar el estado final:
  ///
  /// ```dart
  /// LiveIf(LiveBind.stale.isTrue,
  ///     then: LiveText.literal('Llegó'), otherwise: LiveText(bind('estado')))
  /// ```
  ///
  /// iOS 16.2 o superior y la vista previa; Android no lo evalúa (siempre es
  /// `false`): ahí cambia el estado con `update`.
  static const stale = LiveBind(r'$stale');

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
        'Una condición lleva "bind" y exactamente un operador',
      );
    }
    return LiveCondition(field, ops.single, json[ops.single]);
  }

  /// Evalúa la condición contra [state].
  bool evaluate(Map<String, Object?> state) {
    final v = state[field];
    switch (op) {
      case 'eq':
        return _same(v, value);
      case 'neq':
        return !_same(v, value);
      case 'truthy':
        final on = v != null && v != false && v != 0 && v != '';
        return value == false ? !on : on;
      default:
        final a = _number(v), b = _number(value);
        if (a == null || b == null) return false;
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

/// Un número, o un texto que lo es; un booleano no cuenta.
double? _number(Object? v) => switch (v) {
  num() => v.toDouble(),
  String() => double.tryParse(v),
  _ => null,
};

/// `eq`: si los dos son números se comparan como números; si no, como texto.
bool _same(Object? a, Object? b) {
  final x = _number(a), y = _number(b);
  if (x != null && y != null) return (x - y).abs() < 1e-9;
  return liveText(a) == liveText(b);
}

/// El texto de un valor del estado, igual en Dart, Swift y Kotlin: un entero
/// sin decimales (`5.0` → `5`), un booleano como `true` o `false` y nulo vacío.
String liveText(Object? v) {
  if (v == null) return '';
  if (v is num && v.isFinite && v == v.roundToDouble() && v.abs() < 1e15) {
    return v.toInt().toString();
  }
  return '$v';
}

/// Plantilla `{campo}`: sustituye cada campo por su valor en [state].
String formatTemplate(String fmt, Map<String, Object?> state) =>
    fmt.replaceAllMapped(
      RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}'),
      (m) => liveText(state[m[1]]),
    );
