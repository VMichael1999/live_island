import 'dart:ui' show Color;

import '../components/actions.dart';
import '../components/charts.dart';
import '../components/progress.dart';
import '../components/visuals.dart';
import 'bind.dart';
import 'enums.dart';
import 'json_util.dart';
import 'node.dart';

/// Version of the JSON contract this package writes.
const liveContractVersion = 1;

/// Accent color and background of the lock screen card.
class LiveTheme {
  const LiveTheme({
    required this.accent,
    this.background = LiveBackground.system,
  });

  final Color accent;
  final LiveBackground background;

  Map<String, Object?> toJson() => {
    'accent': colorToHex(accent),
    'background': background.name,
  };

  factory LiveTheme.fromJson(Map<String, Object?> json) => LiveTheme(
    accent: colorFromHex(json['accent']! as String),
    background: enumByName(
      LiveBackground.values,
      json['background'],
      LiveBackground.system,
    ),
  );
}

/// The four zones of the expanded island.
class LiveExpanded {
  const LiveExpanded({this.leading, this.center, this.trailing, this.bottom});

  final LiveNode? leading, center, trailing, bottom;

  Iterable<LiveNode> get nodes =>
      [leading, center, trailing, bottom].whereType<LiveNode>();

  Map<String, Object?> toJson() => compact({
    'leading': leading?.toJson(),
    'center': center?.toJson(),
    'trailing': trailing?.toJson(),
    'bottom': bottom?.toJson(),
  });

  factory LiveExpanded.fromJson(Map<String, Object?> json) {
    LiveNode? n(String k) =>
        json[k] == null
            ? null
            : LiveNode.fromJson(asMap(json[k], 'expanded.$k'));
    return LiveExpanded(
      leading: n('leading'),
      center: n('center'),
      trailing: n('trailing'),
      bottom: n('bottom'),
    );
  }
}

/// Design of the lock screen card: the expanded island's or its own.
class LiveLockScreen {
  const LiveLockScreen.sameAsExpanded() : custom = null;
  const LiveLockScreen.custom(LiveNode this.custom);

  /// `null` = reuses the expanded island.
  final LiveNode? custom;

  bool get isSameAsExpanded => custom == null;

  Map<String, Object?> toJson() => custom?.toJson() ?? {'same': 'expanded'};

  factory LiveLockScreen.fromJson(Map<String, Object?> json) =>
      json['same'] == 'expanded'
          ? const LiveLockScreen.sameAsExpanded()
          : LiveLockScreen.custom(LiveNode.fromJson(json));
}

/// Chip in Android's status bar (only with a Live Update).
class LiveChip {
  const LiveChip._(this.type, {this.bind, this.text});

  /// Minutes left until the date in the [until] field: "6 min".
  const LiveChip.countdown(LiveBind until) : this._('countdown', bind: until);

  /// Short text: 7 characters or fewer are shown in full.
  const LiveChip.text(String text) : this._('text', text: text);

  /// Only the small icon.
  const LiveChip.icon() : this._('icon');

  final String type;
  final LiveBind? bind;
  final String? text;

  Map<String, Object?> toJson() =>
      compact({'t': type, 'bind': bind?.field, 'text': text});

  factory LiveChip.fromJson(Map<String, Object?> json) => switch (json['t']) {
    'countdown' => LiveChip.countdown(LiveBind(json['bind']! as String)),
    'text' => LiveChip.text(json['text']! as String),
    _ => const LiveChip.icon(),
  };
}

/// Android block: a notification with native styles (never `RemoteViews`).
class LiveAndroid {
  const LiveAndroid({
    this.title,
    this.text,
    this.chip,
    this.colorized = false,
    this.progress,
    this.actions,
    this.largeIcon,
    this.subText,
    this.style = LiveAndroidStyle.liveUpdate,
    this.card,
    this.cardCollapsed,
  });

  /// [LiveAndroidStyle.liveUpdate] (the default) or [LiveAndroidStyle.card].
  final LiveAndroidStyle style;

  /// Design of the expanded card with [LiveAndroidStyle.card]: the same tree
  /// of components as the island (row, column, text, image, bar…). If missing,
  /// the lock screen's own card (`LiveLockScreen.custom`) is used.
  final LiveNode? card;

  /// Design of the collapsed card. If missing, [card] is used.
  final LiveNode? cardCollapsed;

  /// Required for Android to promote it to a Live Update.
  final LiveTextSource? title;
  final LiveTextSource? text;
  final LiveChip? chip;

  /// With `true` Android does NOT promote the notification.
  final bool colorized;

  /// Bar, ring or stages. If missing, it is taken from `expanded.bottom`.
  final LiveNode? progress;

  /// Up to three buttons. If missing, they are taken from `expanded.bottom`.
  final List<LiveButton>? actions;

  /// Large image on the right of the notification (driver photo, crest,
  /// logo…): a [LiveImage] or a [LiveAvatar]. If missing, Android uses the
  /// expanded island's avatar or image, or the app logo.
  final LiveVisual? largeIcon;

  /// Small header text next to the app name (for example the vehicle or the
  /// route). If missing, Android shows the bar's stage.
  final LiveTextSource? subText;

  Map<String, Object?> toJson() => compact({
    'title': title?.toAndroidTextJson(),
    'text': text?.toAndroidTextJson(),
    'chip': chip?.toJson(),
    'colorized': colorized,
    'progress': progress?.toJson(),
    'actions': actions == null ? null : [for (final a in actions!) a.toJson()],
    'largeIcon': largeIcon?.toJson(),
    'style': style == LiveAndroidStyle.card ? 'card' : null,
    'card': card?.toJson(),
    'cardCollapsed': cardCollapsed?.toJson(),
    'subText': subText?.toAndroidTextJson(),
  });

  factory LiveAndroid.fromJson(Map<String, Object?> json) {
    LiveTextSource? t(String k) {
      final raw = json[k];
      if (raw == null) return null;
      final m = asMap(raw, 'android.$k');
      if (m['bind'] != null) return LiveBind(m['bind']! as String);
      return _AndroidTextFromJson(m);
    }

    return LiveAndroid(
      title: t('title'),
      text: t('text'),
      subText: t('subText'),
      style:
          json['style'] == 'card'
              ? LiveAndroidStyle.card
              : LiveAndroidStyle.liveUpdate,
      card:
          json['card'] == null
              ? null
              : LiveNode.fromJson(asMap(json['card'], 'android.card')),
      cardCollapsed:
          json['cardCollapsed'] == null
              ? null
              : LiveNode.fromJson(
                asMap(json['cardCollapsed'], 'android.cardCollapsed'),
              ),
      largeIcon:
          json['largeIcon'] == null
              ? null
              : LiveVisual.fromJson(
                asMap(json['largeIcon'], 'android.largeIcon'),
              ),
      chip:
          json['chip'] == null
              ? null
              : LiveChip.fromJson(asMap(json['chip'], 'android.chip')),
      colorized: json['colorized'] == true,
      progress:
          json['progress'] == null
              ? null
              : LiveNode.fromJson(asMap(json['progress'], 'android.progress')),
      actions:
          json['actions'] == null
              ? null
              : [
                for (final a in json['actions']! as List)
                  LiveButton.fromJson(asMap(a, 'android.actions')),
              ],
    );
  }
}

/// Android text read from JSON (literal or template).
class _AndroidTextFromJson implements LiveTextSource {
  _AndroidTextFromJson(this.json);
  final Map<String, Object?> json;
  @override
  Map<String, Object?> toAndroidTextJson() => json;
}

/// Data of an image already reduced by the plugin.
class LiveImageMeta {
  const LiveImageMeta({required this.file, required this.w, required this.h});

  final String file;
  final int w, h;

  Map<String, Object?> toJson() => {'file': file, 'w': w, 'h': h};

  factory LiveImageMeta.fromJson(Map<String, Object?> json) => LiveImageMeta(
    file: json['file']! as String,
    w: (json['w']! as num).toInt(),
    h: (json['h']! as num).toInt(),
  );
}

/// The complete design of an activity. It travels only once, in `start()`.
class LiveLayout {
  const LiveLayout({
    required this.theme,
    this.appLogo,
    this.androidSmallIcon,
    this.compactLeading,
    this.compactTrailing,
    this.minimal,
    this.expanded,
    this.lockScreen,
    this.android,
  });

  final LiveTheme theme;

  /// Lock screen and Android's large icon.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;
  final LiveNode? compactLeading, compactTrailing, minimal;
  final LiveExpanded? expanded;
  final LiveLockScreen? lockScreen;
  final LiveAndroid? android;

  /// A copy of the design changing only what is indicated.
  LiveLayout copyWith({
    LiveTheme? theme,
    LiveVisual? appLogo,
    LiveVisual? androidSmallIcon,
    LiveNode? compactLeading,
    LiveNode? compactTrailing,
    LiveNode? minimal,
    LiveExpanded? expanded,
    LiveLockScreen? lockScreen,
    LiveAndroid? android,
  }) => LiveLayout(
    theme: theme ?? this.theme,
    appLogo: appLogo ?? this.appLogo,
    androidSmallIcon: androidSmallIcon ?? this.androidSmallIcon,
    compactLeading: compactLeading ?? this.compactLeading,
    compactTrailing: compactTrailing ?? this.compactTrailing,
    minimal: minimal ?? this.minimal,
    expanded: expanded ?? this.expanded,
    lockScreen: lockScreen ?? this.lockScreen,
    android: android ?? this.android,
  );

  /// All the nodes of the design (regions, Android block and logos).
  Iterable<LiveNode> get allNodes sync* {
    for (final v in [appLogo, androidSmallIcon]) {
      if (v != null) yield* v.descendants;
    }
    for (final n in [compactLeading, compactTrailing, minimal]) {
      if (n != null) yield* n.descendants;
    }
    for (final n in expanded?.nodes ?? const <LiveNode>[]) {
      yield* n.descendants;
    }
    if (lockScreen?.custom != null) yield* lockScreen!.custom!.descendants;
    if (android?.progress != null) yield* android!.progress!.descendants;
    if (android?.largeIcon != null) yield* android!.largeIcon!.descendants;
    if (android?.card != null) yield* android!.card!.descendants;
    if (android?.cardCollapsed != null) {
      yield* android!.cardCollapsed!.descendants;
    }
    for (final a in android?.actions ?? const <LiveButton>[]) {
      yield* a.descendants;
    }
  }

  /// The design's own images, without repeats (by id).
  List<LiveImage> get images {
    final byId = <String, LiveImage>{};
    for (final n in allNodes) {
      if (n is LiveImage) byId.putIfAbsent(n.id, () => n);
    }
    return byId.values.toList();
  }

  /// Serializes to the JSON contract. [resolved] carries the data of the images
  /// the plugin already reduced; any that are missing get a placeholder with
  /// their original dimensions (or 1 × 1).
  Map<String, Object?> toJson({Map<String, LiveImageMeta>? resolved}) {
    final manifest = <String, Object?>{
      for (final img in images)
        img.id:
            (resolved?[img.id] ??
                    LiveImageMeta(
                      file: '${img.id}.png',
                      w: img.width ?? 1,
                      h: img.height ?? 1,
                    ))
                .toJson(),
    };
    return compact({
      'v': liveContractVersion,
      'theme': theme.toJson(),
      'appLogo': appLogo?.toJson(),
      'androidSmallIcon': androidSmallIcon?.toJson(),
      'images': manifest.isEmpty ? null : manifest,
      'regions': compact({
        'compactLeading': compactLeading?.toJson(),
        'compactTrailing': compactTrailing?.toJson(),
        'minimal': minimal?.toJson(),
        'expanded': expanded?.toJson(),
        'lockScreen': lockScreen?.toJson(),
      }),
      'android': android?.toJson(),
    });
  }

  /// Reads the JSON contract. Images stay as references by id.
  factory LiveLayout.fromJson(Map<String, Object?> json) {
    final version = json['v'];
    if (version != liveContractVersion) {
      throw FormatException('Versión de contrato no soportada: $version');
    }
    final regions = asMap(json['regions'], 'regions');
    LiveNode? n(String k) =>
        regions[k] == null ? null : LiveNode.fromJson(asMap(regions[k], k));
    LiveVisual? v(String k) =>
        json[k] == null ? null : LiveVisual.fromJson(asMap(json[k], k));
    return LiveLayout(
      theme: LiveTheme.fromJson(asMap(json['theme'], 'theme')),
      appLogo: v('appLogo'),
      androidSmallIcon: v('androidSmallIcon'),
      compactLeading: n('compactLeading'),
      compactTrailing: n('compactTrailing'),
      minimal: n('minimal'),
      expanded:
          regions['expanded'] == null
              ? null
              : LiveExpanded.fromJson(asMap(regions['expanded'], 'expanded')),
      lockScreen:
          regions['lockScreen'] == null
              ? null
              : LiveLockScreen.fromJson(
                asMap(regions['lockScreen'], 'lockScreen'),
              ),
      android:
          json['android'] == null
              ? null
              : LiveAndroid.fromJson(asMap(json['android'], 'android')),
    );
  }
}

/// First progress node (bar, ring or stages) inside [roots].
LiveNode? firstProgress(Iterable<LiveNode> roots) {
  for (final root in roots) {
    for (final n in root.descendants) {
      if (n is LiveProgress ||
          n is LiveSegments ||
          n is LiveGauge ||
          n is LiveFlightPath ||
          n is LiveSplitBar) {
        return n;
      }
    }
  }
  return null;
}
