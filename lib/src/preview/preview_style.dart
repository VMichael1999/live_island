import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';

/// Fondo sobre el que se dibuja un componente. Decide colores de texto,
/// barra y botones (ver `progress()` e `iosActions()` del HTML).
enum LiveTone { dark, light, accent }

/// Colores de una superficie, derivados de su [LiveTone] y del acento.
class LiveToneStyle {
  LiveToneStyle(this.tone, this.accent, {double mutedAlpha = .68})
    : fg =
          tone == LiveTone.light
              ? const Color(0xFF111111)
              : const Color(0xFFFFFFFF),
      muted = (tone == LiveTone.light
              ? const Color(0xFF111111)
              : const Color(0xFFFFFFFF))
          .withValues(alpha: mutedAlpha);

  final LiveTone tone;

  /// Color de acento del tema (nunca cambia por superficie).
  final Color accent;
  final Color fg;
  final Color muted;

  bool get isLight => tone == LiveTone.light;
  bool get isAccent => tone == LiveTone.accent;

  /// Color del texto o ícono marcado como `accent`: blanco sobre fondo de acento.
  Color get accentOnSurface => isAccent ? const Color(0xFFFFFFFF) : accent;

  Color get trackBg =>
      isLight ? const Color(0x1F000000) : const Color(0x33FFFFFF);
  Color get fill => isAccent ? const Color(0xFFFFFFFF) : accent;
  Color get trackerBg => isAccent ? const Color(0xFFFFFFFF) : accent;
  Color get trackerFg => isAccent ? accent : const Color(0xFFFFFFFF);
  Color get endIcon =>
      isLight ? const Color(0xFF333333) : const Color(0xFFFFFFFF);
  Color get pendingDot =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E);
  Color get stageMuted =>
      isLight ? const Color(0x8C000000) : const Color(0x99FFFFFF);
  Color get stageStrong =>
      isLight ? const Color(0xFF111111) : const Color(0xFFFFFFFF);

  /// Fondo y texto del botón [index] (0 = principal).
  (Color, Color) button(int index) {
    if (isAccent) {
      return index == 0
          ? (const Color(0xFFFFFFFF), accent)
          : (const Color(0x38FFFFFF), const Color(0xFFFFFFFF));
    }
    if (isLight) {
      return index == 0
          ? (accent, const Color(0xFFFFFFFF))
          : (const Color(0x14000000), const Color(0xFF111111));
    }
    return index == 0
        ? (accent, const Color(0xFFFFFFFF))
        : (const Color(0x24FFFFFF), const Color(0xFFFFFFFF));
  }
}

/// Colores de la notificación de Android (Material 3).
class AndroidTokens {
  const AndroidTokens._(
    this.shade,
    this.card,
    this.title,
    this.body,
    this.status,
  );

  factory AndroidTokens.of(Brightness b) =>
      b == Brightness.dark
          ? const AndroidTokens._(
            Color(0xFF141218),
            Color(0xFF2B2930),
            Color(0xFFE6E0E9),
            Color(0xFFCAC4D0),
            Color(0xFFE6E0E9),
          )
          : const AndroidTokens._(
            Color(0xFFFEF7FF),
            Color(0xFFECE6F0),
            Color(0xFF1D1B20),
            Color(0xFF49454F),
            Color(0xFF1D1B20),
          );

  final Color shade, card, title, body, status;
}
