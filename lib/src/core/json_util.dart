import 'dart:ui' show Color;

/// Removes keys with a null value so the JSON only carries what matters.
Map<String, Object?> compact(Map<String, Object?> map) =>
    Map<String, Object?>.of(map)..removeWhere((_, v) => v == null);

/// `#RRGGBB`, or `#RRGGBBAA` if the color is not opaque.
String colorToHex(Color c) {
  String h(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final rgb = '#${h(c.r)}${h(c.g)}${h(c.b)}'.toUpperCase();
  return c.a == 1.0 ? rgb : '$rgb${h(c.a)}'.toUpperCase();
}

/// Inverse of [colorToHex].
Color colorFromHex(String hex) {
  final s = hex.startsWith('#') ? hex.substring(1) : hex;
  if (s.length == 6) return Color(0xFF000000 | int.parse(s, radix: 16));
  if (s.length == 8) {
    final v = int.parse(s, radix: 16);
    return Color(((v & 0xFF) << 24) | (v >> 8));
  }
  throw FormatException('Invalid color: $hex');
}

/// 32-bit FNV-1a hash in hexadecimal, for stable image ids.
String fnv1a(Iterable<int> bytes) {
  var h = 0x811c9dc5;
  for (final b in bytes) {
    h ^= b & 0xff;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

/// `{ "t": ... }` → typed object, or fails with a clear message.
Map<String, Object?> asMap(Object? v, String where) {
  if (v is Map) return Map<String, Object?>.from(v);
  throw FormatException('Expected an object at $where');
}
