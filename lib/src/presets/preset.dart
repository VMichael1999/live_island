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

/// Folder of the Android icon PNGs the package ships.
const _iconDir = 'packages/live_island_kit/assets/icons';

/// A system icon with its Android PNG: `presetIcon('car.fill', 'car')`.
///
/// [sf] is the SF Symbol (iOS) and [file] the PNG the package ships in
/// `assets/icons/` (Android).
LiveIcon presetIcon(String sf, String file, {bool accent = false}) =>
    LiveIcon.symbol(sf, android: '$_iconDir/$file.png', accent: accent);

/// A sample button: the `id` comes from the label if not specified.
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

/// How a preset shows progress.
enum PresetProgress { none, bar, segments, ring }

/// Sample data of a preset (the same as the HTML gallery's).
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

  /// Highlighted value when it is text.
  final String highlight;

  /// Minutes of the countdown when the highlighted value is a counter.
  final double minutes;
  final double progress;
}

/// Everything that defines a preset's design. Presets are classes with the
/// parameters that change the most; this specification is what builds the
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

  /// Main icon (no accent; the design paints it where appropriate).
  final LiveIcon icon;
  final PresetSample sample;
  final LiveChip chip;
  final LiveVisual? appLogo, androidSmallIcon;

  /// Initials (or [avatarPhoto]) if the preset shows an avatar instead of the icon.
  final String? avatarText;
  final LiveImage? avatarPhoto;

  /// `true`: the highlighted value is a countdown to `llegaA`; otherwise, the text of `destacado`.
  final bool countdown;
  final PresetProgress progress;
  final List<String> stages;
  final bool showPoints;

  /// Shows the stage labels.
  final bool showLabels;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;
  final LiveTrackerSource? tracker;
  final LiveVisual? startIcon, endIcon;
  final List<LiveButton> buttons;
  final LiveBackground lockBackground;

  /// `false` for cases Android does not promote to a Live Update (used in `check()`).
  final bool androidPromotable;
}

/// Builds the design of [spec]. It is the HTML prototype's "generated Dart
/// code" (`renderCode`) turned into a function.
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

/// A ready-to-use design. Each preset is a normal [LiveLayout]: it can be
/// used as is, with [override] or as the starting point of your own.
///
/// The data the design expects (the names bound with `bind`) are always
/// `titulo`, `subtitulo`, `nombre`, `progreso` and `destacado` (text) or
/// `llegaA` (the countdown's date): see [sampleState].
abstract class LivePreset {
  const LivePreset();

  /// The complete specification of the preset.
  LivePresetSpec get spec;

  /// Name of the app shown by the Android preview.
  String get appName => spec.appName;

  /// `false` if Android does not promote this case to a Live Update.
  bool get androidPromotable => spec.androidPromotable;

  /// The preset's design.
  LiveLayout build() => buildPresetLayout(spec);

  /// Sample data to try the design. [now] fixes the time of the
  /// countdown.
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

  /// The preset's design with some parts replaced. Each argument replaces a
  /// whole region; the `expanded*` ones replace only a zone of the expanded
  /// island.
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
