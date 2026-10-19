import 'dart:ui' show Color;

import '../components/actions.dart';
import '../components/charts.dart';
import '../components/progress.dart';
import '../components/visuals.dart';
import 'bind.dart';
import 'enums.dart';
import 'json_util.dart';
import 'node.dart';

/// Versión del contrato JSON que escribe este paquete.
const liveContractVersion = 1;

/// Color de acento y fondo de la tarjeta de bloqueo.
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

/// Las cuatro zonas de la isla expandida.
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

/// Diseño de la tarjeta de bloqueo: el de la isla expandida o uno propio.
class LiveLockScreen {
  const LiveLockScreen.sameAsExpanded() : custom = null;
  const LiveLockScreen.custom(LiveNode this.custom);

  /// `null` = reutiliza la isla expandida.
  final LiveNode? custom;

  bool get isSameAsExpanded => custom == null;

  Map<String, Object?> toJson() => custom?.toJson() ?? {'same': 'expanded'};

  factory LiveLockScreen.fromJson(Map<String, Object?> json) =>
      json['same'] == 'expanded'
          ? const LiveLockScreen.sameAsExpanded()
          : LiveLockScreen.custom(LiveNode.fromJson(json));
}

/// Chip de la barra de estado de Android (solo con Live Update).
class LiveChip {
  const LiveChip._(this.type, {this.bind, this.text});

  /// Minutos que faltan para la fecha del campo [until]: "6 min".
  const LiveChip.countdown(LiveBind until) : this._('countdown', bind: until);

  /// Texto corto: 7 caracteres o menos se ve completo.
  const LiveChip.text(String text) : this._('text', text: text);

  /// Solo el ícono pequeño.
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

/// Bloque Android: notificación con estilos nativos (nunca `RemoteViews`).
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

  /// [LiveAndroidStyle.liveUpdate] (por defecto) o [LiveAndroidStyle.card].
  final LiveAndroidStyle style;

  /// Diseño de la tarjeta expandida con [LiveAndroidStyle.card]: el mismo árbol
  /// de componentes que la isla (fila, columna, texto, imagen, barra…). Si falta,
  /// se usa la tarjeta de bloqueo propia (`LiveLockScreen.custom`).
  final LiveNode? card;

  /// Diseño de la tarjeta colapsada. Si falta, se usa [card].
  final LiveNode? cardCollapsed;

  /// Obligatorio para que Android promueva a Live Update.
  final LiveTextSource? title;
  final LiveTextSource? text;
  final LiveChip? chip;

  /// Con `true` Android NO promueve la notificación.
  final bool colorized;

  /// Barra, anillo o etapas. Si falta, se toma de `expanded.bottom`.
  final LiveNode? progress;

  /// Hasta tres botones. Si faltan, se toman de `expanded.bottom`.
  final List<LiveButton>? actions;

  /// Imagen grande a la derecha de la notificación (foto del conductor, escudo,
  /// logo…): una [LiveImage] o un [LiveAvatar]. Si falta, Android usa el avatar
  /// o la imagen de la isla expandida o el logo de la app.
  final LiveVisual? largeIcon;

  /// Texto pequeño del encabezado, junto al nombre de la app (por ejemplo el
  /// vehículo o la ruta). Si falta, Android muestra la etapa de la barra.
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

/// Texto de Android leído de JSON (literal o plantilla).
class _AndroidTextFromJson implements LiveTextSource {
  _AndroidTextFromJson(this.json);
  final Map<String, Object?> json;
  @override
  Map<String, Object?> toAndroidTextJson() => json;
}

/// Datos de una imagen ya reducida por el plugin.
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

/// El diseño completo de una actividad. Viaja una sola vez, en `start()`.
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

  /// Pantalla de bloqueo e ícono grande de Android.
  final LiveVisual? appLogo;

  /// Silueta de un color para la barra de estado de Android.
  final LiveVisual? androidSmallIcon;
  final LiveNode? compactLeading, compactTrailing, minimal;
  final LiveExpanded? expanded;
  final LiveLockScreen? lockScreen;
  final LiveAndroid? android;

  /// Copia del diseño cambiando solo lo indicado.
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

  /// Todos los nodos del diseño (regiones, bloque Android y logos).
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

  /// Imágenes propias del diseño, sin repetir (por id).
  List<LiveImage> get images {
    final byId = <String, LiveImage>{};
    for (final n in allNodes) {
      if (n is LiveImage) byId.putIfAbsent(n.id, () => n);
    }
    return byId.values.toList();
  }

  /// Serializa al contrato JSON. [resolved] trae los datos de las imágenes que
  /// el plugin ya redujo; las que falten llevan un marcador con sus
  /// dimensiones originales (o 1 × 1).
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

  /// Lee el contrato JSON. Las imágenes quedan como referencias por id.
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

/// Primer nodo de progreso (barra, anillo o etapas) dentro de [roots].
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
