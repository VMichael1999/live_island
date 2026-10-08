import 'dart:ui' show Color;

/// Quita las claves con valor nulo para que el JSON solo lleve lo que importa.
Map<String, Object?> compact(Map<String, Object?> map) =>
    Map<String, Object?>.of(map)..removeWhere((_, v) => v == null);

/// `#RRGGBB`, o `#RRGGBBAA` si el color no es opaco.
String colorToHex(Color c) {
  String h(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final rgb = '#${h(c.r)}${h(c.g)}${h(c.b)}'.toUpperCase();
  return c.a == 1.0 ? rgb : '$rgb${h(c.a)}'.toUpperCase();
}

/// Inversa de [colorToHex].
Color colorFromHex(String hex) {
  final s = hex.startsWith('#') ? hex.substring(1) : hex;
  if (s.length == 6) return Color(0xFF000000 | int.parse(s, radix: 16));
  if (s.length == 8) {
    final v = int.parse(s, radix: 16);
    return Color(((v & 0xFF) << 24) | (v >> 8));
  }
  throw FormatException('Color inválido: $hex');
}

/// Hash FNV-1a de 32 bits en hexadecimal, para ids estables de imágenes.
String fnv1a(Iterable<int> bytes) {
  var h = 0x811c9dc5;
  for (final b in bytes) {
    h ^= b & 0xff;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

/// `{ "t": ... }` → objeto tipado, o falla con un mensaje claro.
Map<String, Object?> asMap(Object? v, String where) {
  if (v is Map) return Map<String, Object?>.from(v);
  throw FormatException('Se esperaba un objeto en $where');
}
