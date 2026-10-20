/// A text source Android can show (the notification's title and text): a
/// state field, a literal or a template.
abstract interface class LiveTextSource {
  Map<String, Object?> toAndroidTextJson();
}

/// A binding to a state field. The names are chosen by whoever uses the package.
class LiveBind implements LiveTextSource {
  const LiveBind(this.field);

  /// The "stale" state: becomes `true` when the `staleAfter` date arrives and
  /// the system redraws the activity, with no push or update. Use it in a
  /// `LiveIf` to show the final state:
  ///
  /// ```dart
  /// LiveIf(LiveBind.stale.isTrue,
  ///     then: LiveText.literal('Arrived'), otherwise: LiveText(bind('status')))
  /// ```
  ///
  /// iOS 16.2 or later and the preview; Android does not evaluate it (it is
  /// always `false`): there, change the state with `update`.
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

/// `bind('stage')`: binds to the `stage` field of the state.
LiveBind bind(String field) => LiveBind(field);

/// Condition of a `LiveIf`: a field and exactly one operator.
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
        'A condition takes "bind" and exactly one operator',
      );
    }
    return LiveCondition(field, ops.single, json[ops.single]);
  }

  /// Evaluates the condition against [state].
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

/// A number, or a string that is one; a boolean does not count.
double? _number(Object? v) => switch (v) {
  num() => v.toDouble(),
  String() => double.tryParse(v),
  _ => null,
};

/// `eq`: if both are numbers they are compared as numbers; otherwise, as text.
bool _same(Object? a, Object? b) {
  final x = _number(a), y = _number(b);
  if (x != null && y != null) return (x - y).abs() < 1e-9;
  return liveText(a) == liveText(b);
}

/// The text of a state value, the same in Dart, Swift and Kotlin: an integer
/// without decimals (`5.0` → `5`), a boolean as `true` or `false` and null as empty.
String liveText(Object? v) {
  if (v == null) return '';
  if (v is num && v.isFinite && v == v.roundToDouble() && v.abs() < 1e15) {
    return v.toInt().toString();
  }
  return '$v';
}

/// `{field}` template: replaces each field with its value in [state].
String formatTemplate(String fmt, Map<String, Object?> state) =>
    fmt.replaceAllMapped(
      RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}'),
      (m) => liveText(state[m[1]]),
    );
