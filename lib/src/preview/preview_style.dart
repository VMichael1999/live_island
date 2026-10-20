import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';

/// Background a component is drawn on. It decides the colors of text,
/// bar and buttons (see `progress()` and `iosActions()` in the HTML).
enum LiveTone { dark, light, accent }

/// Colors of a surface, derived from its [LiveTone] and the accent.
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

  /// Accent color of the theme (it never changes per surface).
  final Color accent;
  final Color fg;
  final Color muted;

  bool get isLight => tone == LiveTone.light;
  bool get isAccent => tone == LiveTone.accent;

  /// Color of the text or icon marked `accent`: white on an accent background.
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

  /// Background and text of button [index] (0 = main).
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

/// Colors of the Android notification (Material 3).
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
