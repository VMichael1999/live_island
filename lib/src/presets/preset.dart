import 'dart:ui' show Color;

import '../components/actions.dart';
import '../components/layout_nodes.dart';
import '../components/progress.dart';
import '../components/text.dart';
import '../components/visuals.dart';
import '../core/bind.dart';
import '../core/enums.dart';
import '../core/layout.dart';
import '../core/node.dart';

/// Carpeta de los PNG de íconos de Android que trae el paquete.
const _iconDir = 'packages/live_island/assets/icons';

/// Un ícono del sistema con su PNG de Android: `presetIcon('car.fill', 'car')`.
///
/// [sf] es el SF Symbol (iOS) y [file] el PNG que el paquete trae en
/// `assets/icons/` (Android).
LiveIcon presetIcon(String sf, String file, {bool accent = false}) =>
    LiveIcon.symbol(sf, android: '$_iconDir/$file.png', accent: accent);

/// Un botón de ejemplo: el `id` sale de la etiqueta si no se indica.
LiveButton presetButton(String label, LiveIcon? icon, {String? id}) {
  final auto = label
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return LiveButton(
    id: id ?? (auto.isEmpty ? 'accion' : auto),
    label: label,
    icon: icon,
  );
}

/// Cómo se muestra el avance de un preset.
enum PresetProgress { none, bar, segments, ring }

/// Datos de ejemplo de un preset (los mismos de la galería del HTML).
class PresetSample {
  const PresetSample({
    required this.title,
    required this.subtitle,
    required this.name,
    this.highlight = '',
    this.minutes = 5,
    this.progress = 0.4,
  });

  final String title, subtitle, name;

  /// Dato destacado cuando es texto.
  final String highlight;

  /// Minutos de la cuenta regresiva cuando el dato destacado es un contador.
  final double minutes;
  final double progress;
}

/// Todo lo que define el diseño de un preset. Los presets son clases con los
/// parámetros que más se cambian; esta especificación es lo que construye el
/// [LiveLayout].
class LivePresetSpec {
  LivePresetSpec({
    required this.id,
    required this.appName,
    required this.accent,
    required this.icon,
    required this.sample,
    required this.chip,
    this.appLogo,
    this.androidSmallIcon,
    this.avatarText,
    this.avatarPhoto,
    this.countdown = false,
    this.progress = PresetProgress.none,
    this.stages = const [],
    this.showPoints = false,
    this.showLabels = true,
    this.progressStyle,
    this.tracker,
    this.startIcon,
    this.endIcon,
    this.buttons = const [],
    this.lockBackground = LiveBackground.system,
    this.androidPromotable = true,
  });

  final String id, appName;
  final Color accent;

  /// Ícono principal (sin acento; el diseño lo pinta donde corresponde).
  final LiveIcon icon;
  final PresetSample sample;
  final LiveChip chip;
  final LiveVisual? appLogo, androidSmallIcon;

  /// Iniciales (o [avatarPhoto]) si el preset muestra un avatar en lugar del ícono.
  final String? avatarText;
  final LiveImage? avatarPhoto;

  /// `true`: el dato destacado es una cuenta regresiva hasta `llegaA`; si no, el texto de `destacado`.
  final bool countdown;
  final PresetProgress progress;
  final List<String> stages;
  final bool showPoints;

  /// Muestra las etiquetas de las etapas.
  final bool showLabels;

  /// Grosor, colores, esquinas y tamaños de la barra (o el anillo).
  final LiveProgressStyle? progressStyle;
  final LiveTrackerSource? tracker;
  final LiveVisual? startIcon, endIcon;
  final List<LiveButton> buttons;
  final LiveBackground lockBackground;

  /// `false` en casos que Android no promueve a Live Update (se usa en `check()`).
  final bool androidPromotable;
}

/// Construye el diseño de [spec]. Es el "Código Dart generado" del HTML de
/// prototipos (`renderCode`) hecho función.
LiveLayout buildPresetLayout(LivePresetSpec spec) {
  final accentIcon = spec.icon.withAccent();
  final hasAvatar = spec.avatarText != null || spec.avatarPhoto != null;
  final ring = spec.progress == PresetProgress.ring;

  final LiveVisual lead =
      hasAvatar
          ? (spec.avatarPhoto != null
              ? LiveAvatar.photo(spec.avatarPhoto!)
              : LiveAvatar(spec.avatarText!))
          : accentIcon;

  final highlight =
      spec.countdown
          ? LiveText.countdown(const LiveBind('llegaA'))
          : const LiveText(LiveBind('destacado'));

  LiveNode? progress;
  switch (spec.progress) {
    case PresetProgress.segments when spec.stages.length > 1:
      progress = LiveSegments(
        value: const LiveBind('progreso'),
        labels: spec.stages,
        points: spec.showPoints,
        showLabels: spec.showLabels,
        style: spec.progressStyle,
        tracker: spec.tracker,
        startIcon: spec.startIcon,
        endIcon: spec.endIcon,
      );
    case PresetProgress.bar || PresetProgress.segments:
      progress = LiveProgress.bar(
        value: const LiveBind('progreso'),
        style: spec.progressStyle,
        tracker: spec.tracker,
        startIcon: spec.startIcon,
        endIcon: spec.endIcon,
      );
    case PresetProgress.ring || PresetProgress.none:
      progress = null; // el anillo va a la derecha, no abajo
  }

  final theme = LiveTheme(accent: spec.accent, background: spec.lockBackground);

  return LiveLayout(
    theme: theme,
    appLogo: spec.appLogo ?? spec.icon,
    androidSmallIcon: spec.androidSmallIcon,
    compactLeading: lead,
    compactTrailing: LiveText.from(
      highlight,
      size: 15,
      weight: 600,
      accent: true,
    ),
    minimal:
        ring
            ? LiveProgress.ring(
              value: const LiveBind('progreso'),
              child: hasAvatar ? null : accentIcon,
            )
            : lead,
    expanded: LiveExpanded(
      leading:
          hasAvatar
              ? lead
              : LiveBox(child: accentIcon, size: 46, radius: 14, tint: 0.22),
      center: const LiveColumn([
        LiveText(LiveBind('titulo'), size: 15, weight: 600, lines: 2),
        LiveText(LiveBind('subtitulo'), size: 13, muted: true),
      ]),
      trailing:
          ring
              ? LiveProgress.ring(
                value: const LiveBind('progreso'),
                size: 46,
                style: spec.progressStyle,
              )
              : LiveColumn([
                LiveText.from(highlight, size: 22, weight: 700, accent: true),
                const LiveText(LiveBind('nombre'), size: 12, muted: true),
              ], align: LiveAlign.end),
      bottom: LiveColumn([
        if (progress != null) progress,
        if (ring)
          LiveRow([
            const LiveSpacer(),
            LiveText.from(highlight, size: 12, muted: true),
            const LiveText.literal('·', size: 12, muted: true),
            const LiveText(LiveBind('nombre'), size: 12, muted: true),
            const LiveSpacer(),
          ], gap: 4),
        if (spec.buttons.isNotEmpty) LiveRow(spec.buttons),
      ], gap: 12),
    ),
    lockScreen: const LiveLockScreen.sameAsExpanded(),
    android: LiveAndroid(
      title: const LiveBind('titulo'),
      text: const LiveText.format('{subtitulo} · {nombre}'),
      chip: spec.chip,
    ),
  );
}

/// Un diseño listo para usar. Cada preset es un [LiveLayout] normal: se puede
/// usar tal cual, con [override] o como punto de partida de uno propio.
///
/// Los datos que espera el diseño (los nombres que se enlazan con `bind`) son
/// siempre `titulo`, `subtitulo`, `nombre`, `progreso` y `destacado` (texto) o
/// `llegaA` (fecha de la cuenta regresiva): ver [sampleState].
abstract class LivePreset {
  const LivePreset();

  /// La especificación completa del preset.
  LivePresetSpec get spec;

  /// Nombre de la app que muestra la vista previa de Android.
  String get appName => spec.appName;

  /// `false` si Android no promueve este caso a Live Update.
  bool get androidPromotable => spec.androidPromotable;

  /// El diseño del preset.
  LiveLayout build() => buildPresetLayout(spec);

  /// Datos de ejemplo para probar el diseño. [now] fija la hora de la cuenta
  /// regresiva.
  Map<String, Object?> sampleState({DateTime? now}) {
    final s = spec.sample;
    return {
      'titulo': s.title,
      'subtitulo': s.subtitle,
      'nombre': s.name,
      if (spec.countdown)
        'llegaA': (now ?? DateTime.now()).add(
          Duration(milliseconds: (s.minutes * 60000).round()),
        )
      else
        'destacado': s.highlight,
      'progreso': s.progress,
    };
  }

  /// El diseño del preset con algunas partes reemplazadas. Cada argumento
  /// reemplaza una región completa; los `expanded*` reemplazan solo una zona
  /// de la isla expandida.
  LiveLayout override({
    LiveTheme? theme,
    LiveVisual? appLogo,
    LiveVisual? androidSmallIcon,
    LiveNode? compactLeading,
    LiveNode? compactTrailing,
    LiveNode? minimal,
    LiveExpanded? expanded,
    LiveNode? expandedLeading,
    LiveNode? expandedCenter,
    LiveNode? expandedTrailing,
    LiveNode? expandedBottom,
    LiveLockScreen? lockScreen,
    LiveAndroid? android,
  }) {
    final base = build();
    final e = expanded ?? base.expanded ?? const LiveExpanded();
    return base.copyWith(
      theme: theme,
      appLogo: appLogo,
      androidSmallIcon: androidSmallIcon,
      compactLeading: compactLeading,
      compactTrailing: compactTrailing,
      minimal: minimal,
      expanded: LiveExpanded(
        leading: expandedLeading ?? e.leading,
        center: expandedCenter ?? e.center,
        trailing: expandedTrailing ?? e.trailing,
        bottom: expandedBottom ?? e.bottom,
      ),
      lockScreen: lockScreen,
      android: android,
    );
  }
}
