import 'dart:convert';

/// Utilidades para el estado: lo único que viaja en cada actualización.
abstract final class LiveState {
  /// Límite de ActivityKit por actualización.
  static const maxBytes = 4096;

  static final _key = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  /// Convierte el estado a tipos simples (las fechas pasan a ISO 8601 UTC) y
  /// valida que todo cumpla `state.schema.json`.
  static Map<String, Object?> normalize(Map<String, Object?> state) {
    if (state.length > 64) {
      throw ArgumentError('El estado admite como máximo 64 campos');
    }
    return {
      for (final e in state.entries) _checkKey(e.key): _value(e.key, e.value),
    };
  }

  /// Bytes que pesa el estado ya normalizado, en UTF-8.
  static int byteSize(Map<String, Object?> state) =>
      utf8.encode(jsonEncode(normalize(state))).length;

  static String _checkKey(String key) {
    if (!_key.hasMatch(key)) {
      throw ArgumentError.value(key, 'campo',
          'Debe empezar con letra o guion bajo y usar solo letras, números y _');
    }
    return key;
  }

  static Object? _value(String key, Object? v) {
    if (v == null || v is String || v is bool) return v;
    if (v is num) {
      if (v.isNaN || v.isInfinite) {
        throw ArgumentError.value(v, key, 'Los números deben ser finitos');
      }
      return v;
    }
    if (v is DateTime) return v.toUtc().toIso8601String();
    throw ArgumentError.value(v, key,
        'Solo se admiten texto, número, booleano, nulo y fecha (${v.runtimeType})');
  }
}
