import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' show Color;

import '../core/enums.dart';
import '../core/bind.dart';
import '../core/json_util.dart';
import '../core/node.dart';

/// Un ícono del sistema, una imagen propia o un avatar: todo lo que puede ir
/// donde va un ícono (ver docs/PROMPT.md §5.1).
sealed class LiveVisual extends LiveNode {
  const LiveVisual();

  factory LiveVisual.fromJson(Map<String, Object?> json) =>
      switch (json['t']) {
        'icon' => LiveIcon.fromJson(json),
        'image' => LiveImage.fromJson(json),
        'avatar' => LiveAvatar.fromJson(json),
        final t => throw FormatException('Visual desconocido: $t'),
      };
}

/// Algo que se puede usar como ícono que avanza sobre la barra de progreso.
abstract interface class LiveTrackerSource {
  LiveTracker asTracker();
}

/// Ícono del sistema: un SF Symbol en iOS y un PNG en Android.
class LiveIcon extends LiveVisual implements LiveTrackerSource {
  const LiveIcon.symbol(
    this.sf, {
    this.android,
    this.size,
    this.accent = false,
    this.color,
  });

  /// Nombre del SF Symbol (`car.fill`).
  final String sf;

  /// Ruta del PNG o vector para Android (`assets/live/car.png`).
  final String? android;
  final double? size;

  /// Pintar con el color de acento del tema.
  final bool accent;
  final Color? color;

  @override
  String get type => 'icon';

  @override
  LiveTracker asTracker() => LiveTracker(this);

  @override
  Map<String, Object?> toJson() => compact({
        't': 'icon',
        'sf': sf,
        'android': android,
        'size': size,
        'accent': accent ? true : null,
        'color': color == null ? null : colorToHex(color!),
      });

  factory LiveIcon.fromJson(Map<String, Object?> json) => LiveIcon.symbol(
        json['sf']! as String,
        android: json['android'] as String?,
        size: (json['size'] as num?)?.toDouble(),
        accent: json['accent'] == true,
        color: json['color'] == null
            ? null
            : colorFromHex(json['color']! as String),
      );
}

/// Origen de una imagen propia.
enum LiveImageSource { asset, network, file, memory, reference }

/// Imagen propia (logo, foto, ilustración). Se respeta su proporción.
class LiveImage extends LiveVisual implements LiveTrackerSource {
  /// Imagen de los assets de la app (`assets/logo.png`).
  LiveImage.asset(
    String path, {
    this.fit = LiveFit.contain,
    this.shape = LiveShape.rounded,
    this.size,
    this.byteSize,
    this.width,
    this.height,
  })  : source = LiveImageSource.asset,
        key = path,
        bytes = null,
        id = 'asset_${_slug(path)}';

  /// Imagen de red. La descarga la app, nunca el Widget Extension.
  LiveImage.network(
    String url, {
    this.fit = LiveFit.contain,
    this.shape = LiveShape.rounded,
    this.size,
    this.byteSize,
    this.width,
    this.height,
  })  : source = LiveImageSource.network,
        key = url,
        bytes = null,
        id = 'net_${fnv1a(url.codeUnits)}';

  /// Imagen de un archivo local.
  LiveImage.file(
    File file, {
    this.fit = LiveFit.contain,
    this.shape = LiveShape.rounded,
    this.size,
    this.byteSize,
    this.width,
    this.height,
  })  : source = LiveImageSource.file,
        key = file.path,
        bytes = null,
        id = 'file_${fnv1a(file.path.codeUnits)}';

  /// Imagen en memoria. Su peso se conoce solo.
  LiveImage.memory(
    Uint8List data, {
    this.fit = LiveFit.contain,
    this.shape = LiveShape.rounded,
    this.size,
    this.width,
    this.height,
  })  : source = LiveImageSource.memory,
        key = '',
        bytes = data,
        byteSize = data.lengthInBytes,
        id = 'mem_${fnv1a(data)}';

  /// Referencia a una imagen ya registrada en `layout.images` (la usa
  /// `fromJson`; el plugin la resuelve).
  LiveImage.reference(
    this.id, {
    this.fit = LiveFit.contain,
    this.shape = LiveShape.rounded,
    this.size,
  })  : source = LiveImageSource.reference,
        key = id,
        bytes = null,
        byteSize = null,
        width = null,
        height = null;

  final LiveImageSource source;

  /// Ruta, URL o ruta de archivo según [source].
  final String key;
  final Uint8List? bytes;

  /// Id estable que une el nodo con `layout.images`.
  final String id;
  final LiveFit fit;
  final LiveShape shape;
  final double? size;

  /// Peso original en bytes, si se conoce (solo informa a `check()`).
  final int? byteSize;

  /// Dimensiones originales, si se conocen (para guardar la proporción).
  final int? width;
  final int? height;

  @override
  String get type => 'image';

  @override
  LiveTracker asTracker() => LiveTracker(this);

  @override
  Map<String, Object?> toJson() => compact({
        't': 'image',
        'img': id,
        'fit': fit == LiveFit.contain ? null : fit.name,
        'shape': shape == LiveShape.rounded ? null : shape.name,
        'size': size,
      });

  factory LiveImage.fromJson(Map<String, Object?> json) => LiveImage.reference(
        json['img']! as String,
        fit: enumByName(LiveFit.values, json['fit'], LiveFit.contain),
        shape: enumByName(LiveShape.values, json['shape'], LiveShape.rounded),
        size: (json['size'] as num?)?.toDouble(),
      );

  static String _slug(String path) =>
      path.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');
}

/// Avatar con iniciales (círculo de acento) o con foto circular.
class LiveAvatar extends LiveVisual {
  const LiveAvatar(this.text, {this.size})
      : bindText = null,
        photo = null;

  /// Iniciales tomadas de un campo del estado.
  const LiveAvatar.bound(LiveBind this.bindText, {this.size})
      : text = null,
        photo = null;

  /// Foto circular.
  const LiveAvatar.photo(LiveImage this.photo, {this.size})
      : text = null,
        bindText = null;

  final String? text;
  final LiveBind? bindText;
  final LiveImage? photo;
  final double? size;

  @override
  String get type => 'avatar';

  @override
  Iterable<LiveNode> get children => [if (photo != null) photo!];

  @override
  Map<String, Object?> toJson() => compact({
        't': 'avatar',
        'text': text,
        'bind': bindText?.field,
        'img': photo?.id,
        'size': size,
      });

  factory LiveAvatar.fromJson(Map<String, Object?> json) {
    final size = (json['size'] as num?)?.toDouble();
    if (json['img'] != null) {
      return LiveAvatar.photo(
          LiveImage.reference(json['img']! as String, shape: LiveShape.circle),
          size: size);
    }
    if (json['bind'] != null) {
      return LiveAvatar.bound(LiveBind(json['bind']! as String), size: size);
    }
    return LiveAvatar(json['text'] as String? ?? '', size: size);
  }
}

/// Ícono o imagen que avanza sobre la barra según el progreso.
class LiveTracker implements LiveTrackerSource {
  const LiveTracker(
    this.visual, {
    this.height = 24,
    this.background = LiveTrackerBackground.accentCircle,
  });

  /// Un [LiveIcon] o un [LiveImage].
  final LiveVisual visual;

  /// Solo imagen: alto fijo en pt; el ancho sale de la proporción.
  final double height;
  final LiveTrackerBackground background;

  @override
  LiveTracker asTracker() => this;

  Map<String, Object?> toJson() => {
        'visual': visual.toJson(),
        'height': height,
        'background': background.name,
      };

  factory LiveTracker.fromJson(Map<String, Object?> json) => LiveTracker(
        LiveVisual.fromJson(asMap(json['visual'], 'tracker.visual')),
        height: (json['height'] as num?)?.toDouble() ?? 24,
        background: enumByName(LiveTrackerBackground.values, json['background'],
            LiveTrackerBackground.accentCircle),
      );
}
