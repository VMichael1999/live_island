import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' show Color;

import '../core/enums.dart';
import '../core/bind.dart';
import '../core/json_util.dart';
import '../core/node.dart';

/// A system icon, your own image or an avatar: everything that can go where
/// an icon goes (see doc/PROMPT.md §5.1).
sealed class LiveVisual extends LiveNode {
  const LiveVisual();

  factory LiveVisual.fromJson(Map<String, Object?> json) => switch (json['t']) {
    'icon' => LiveIcon.fromJson(json),
    'image' => LiveImage.fromJson(json),
    'avatar' => LiveAvatar.fromJson(json),
    final t => throw FormatException('Visual desconocido: $t'),
  };
}

/// Something that can be used as the icon that moves along the progress bar.
abstract interface class LiveTrackerSource {
  LiveTracker asTracker();
}

/// System icon: an SF Symbol on iOS and a PNG on Android.
class LiveIcon extends LiveVisual implements LiveTrackerSource {
  const LiveIcon.symbol(
    this.sf, {
    this.android,
    this.size,
    this.accent = false,
    this.color,
  });

  /// Name of the SF Symbol (`car.fill`).
  final String sf;

  /// Path of the PNG or vector for Android (`assets/live/car.png`).
  final String? android;
  final double? size;

  /// Paint with the theme's accent color.
  final bool accent;
  final Color? color;

  @override
  String get type => 'icon';

  /// The same icon painted (or not) with the accent color.
  LiveIcon withAccent([bool accent = true]) => LiveIcon.symbol(
    sf,
    android: android,
    size: size,
    accent: accent,
    color: color,
  );

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
    color:
        json['color'] == null ? null : colorFromHex(json['color']! as String),
  );
}

/// Origin of your own image.
enum LiveImageSource { asset, network, file, memory, reference }

/// Your own image (logo, photo, illustration). Its proportion is respected.
class LiveImage extends LiveVisual implements LiveTrackerSource {
  /// An image from the app's assets (`assets/logo.png`).
  LiveImage.asset(
    String path, {
    this.fit = LiveFit.contain,
    this.shape = LiveShape.rounded,
    this.size,
    this.fixedHeight,
    this.byteSize,
    this.width,
    this.height,
  }) : source = LiveImageSource.asset,
       key = path,
       bytes = null,
       id = 'asset_${_slug(path)}';

  /// A network image. The app downloads it, never the Widget Extension.
  LiveImage.network(
    String url, {
    this.fit = LiveFit.contain,
    this.shape = LiveShape.rounded,
    this.size,
    this.fixedHeight,
    this.byteSize,
    this.width,
    this.height,
  }) : source = LiveImageSource.network,
       key = url,
       bytes = null,
       id = 'net_${fnv1a(url.codeUnits)}';

  /// An image from a local file.
  LiveImage.file(
    File file, {
    this.fit = LiveFit.contain,
    this.shape = LiveShape.rounded,
    this.size,
    this.fixedHeight,
    this.byteSize,
    this.width,
    this.height,
  }) : source = LiveImageSource.file,
       key = file.path,
       bytes = null,
       id = 'file_${fnv1a(file.path.codeUnits)}';

  /// An in-memory image. Its weight is known on its own.
  LiveImage.memory(
    Uint8List data, {
    this.fit = LiveFit.contain,
    this.shape = LiveShape.rounded,
    this.size,
    this.fixedHeight,
    this.width,
    this.height,
  }) : source = LiveImageSource.memory,
       key = '',
       bytes = data,
       byteSize = data.lengthInBytes,
       id = 'mem_${fnv1a(data)}';

  /// Reference to an image already registered in `layout.images` (used by
  /// `fromJson`; the plugin resolves it).
  LiveImage.reference(
    this.id, {
    this.fit = LiveFit.contain,
    this.shape = LiveShape.rounded,
    this.size,
    this.fixedHeight,
  }) : source = LiveImageSource.reference,
       key = id,
       bytes = null,
       byteSize = null,
       width = null,
       height = null;

  LiveImage._copy(LiveImage o, {double? size, double? fixedHeight})
    : source = o.source,
      key = o.key,
      bytes = o.bytes,
      id = o.id,
      fit = o.fit,
      shape = o.shape,
      size = size ?? o.size,
      fixedHeight = fixedHeight ?? o.fixedHeight,
      byteSize = o.byteSize,
      width = o.width,
      height = o.height;

  /// The same image at another size: useful to use a crest or logo in the
  /// compact island (small) and the expanded one (large).
  LiveImage withSize(double size) => LiveImage._copy(this, size: size);

  /// The same image with a fixed height in pt (the width follows its proportion).
  LiveImage withHeight(double height) =>
      LiveImage._copy(this, fixedHeight: height);

  final LiveImageSource source;

  /// Path, URL or file path depending on [source].
  final String key;
  final Uint8List? bytes;

  /// Stable id that links the node to `layout.images`.
  final String id;
  final LiveFit fit;
  final LiveShape shape;
  final double? size;

  /// Fixed height in pt with the width following the image's proportion,
  /// with no cropping or shaping: for wide images with no background (a driver
  /// with their car). With this, [size] is ignored.
  final double? fixedHeight;

  /// Original weight in bytes, if known (only informs `check()`).
  final int? byteSize;

  /// Original dimensions, if known (to keep the proportion).
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
    'h': fixedHeight,
  });

  factory LiveImage.fromJson(Map<String, Object?> json) => LiveImage.reference(
    json['img']! as String,
    fit: enumByName(LiveFit.values, json['fit'], LiveFit.contain),
    shape: enumByName(LiveShape.values, json['shape'], LiveShape.rounded),
    size: (json['size'] as num?)?.toDouble(),
    fixedHeight: (json['h'] as num?)?.toDouble(),
  );

  static String _slug(String path) => path
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

/// Avatar with initials (accent circle) or with a circular photo.
class LiveAvatar extends LiveVisual {
  const LiveAvatar(this.text, {this.size}) : bindText = null, photo = null;

  /// Initials taken from a state field.
  const LiveAvatar.bound(LiveBind this.bindText, {this.size})
    : text = null,
      photo = null;

  /// Circular photo.
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
        size: size,
      );
    }
    if (json['bind'] != null) {
      return LiveAvatar.bound(LiveBind(json['bind']! as String), size: size);
    }
    return LiveAvatar(json['text'] as String? ?? '', size: size);
  }
}

/// Icon or image that moves along the bar according to progress.
class LiveTracker implements LiveTrackerSource {
  const LiveTracker(
    this.visual, {
    this.height = 24,
    this.background = LiveTrackerBackground.accentCircle,
  });

  /// A [LiveIcon] or a [LiveImage].
  final LiveVisual visual;

  /// Image only: fixed height in pt; the width follows the proportion.
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
    background: enumByName(
      LiveTrackerBackground.values,
      json['background'],
      LiveTrackerBackground.accentCircle,
    ),
  );
}
