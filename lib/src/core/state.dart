import 'dart:convert';

/// Utilities for the state: the only thing that travels with each update.
abstract final class LiveState {
  /// ActivityKit's limit per update.
  static const maxBytes = 4096;

  static final _key = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  /// Converts the state to simple types (dates become ISO 8601 UTC) and
  /// validates that everything complies with `state.schema.json`.
  static Map<String, Object?> normalize(Map<String, Object?> state) {
    if (state.length > 64) {
      throw ArgumentError('The state allows at most 64 fields');
    }
    return {
      for (final e in state.entries) _checkKey(e.key): _value(e.key, e.value),
    };
  }

  /// Bytes the already-normalized state weighs, in UTF-8.
  static int byteSize(Map<String, Object?> state) =>
      utf8.encode(jsonEncode(normalize(state))).length;

  static String _checkKey(String key) {
    if (!_key.hasMatch(key)) {
      throw ArgumentError.value(
        key,
        'field',
        'Must start with a letter or underscore and use only letters, digits and _',
      );
    }
    return key;
  }

  static Object? _value(String key, Object? v) {
    if (v == null || v is String || v is bool) return v;
    if (v is num) {
      if (v.isNaN || v.isInfinite) {
        throw ArgumentError.value(v, key, 'Numbers must be finite');
      }
      return v;
    }
    if (v is DateTime) return v.toUtc().toIso8601String();
    throw ArgumentError.value(
      v,
      key,
      'Only text, number, boolean, null and date are allowed (${v.runtimeType})',
    );
  }
}
