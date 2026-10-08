import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import '../components/visuals.dart';
import '../core/image_slots.dart';
import '../core/layout.dart';
import 'live_island_platform.dart';

/// Lee los bytes de una imagen según su origen. Las de red las descarga la
/// app, nunca el Widget Extension.
typedef LiveImageReader = Future<Uint8List> Function(LiveImage image);

Future<Uint8List> defaultImageReader(LiveImage image) async {
  switch (image.source) {
    case LiveImageSource.memory:
      return image.bytes!;
    case LiveImageSource.asset:
      return (await rootBundle.load(image.key)).buffer.asUint8List();
    case LiveImageSource.file:
      return File(image.key).readAsBytes();
    case LiveImageSource.network:
      final client = HttpClient();
      try {
        final req = await client.getUrl(Uri.parse(image.key));
        final res = await req.close();
        if (res.statusCode != 200) {
          throw HttpException(
            'HTTP ${res.statusCode}',
            uri: Uri.parse(image.key),
          );
        }
        final b = BytesBuilder(copy: false);
        await for (final chunk in res) {
          b.add(chunk);
        }
        return b.takeBytes();
      } finally {
        client.close();
      }
    case LiveImageSource.reference:
      throw StateError(
        'La imagen "${image.id}" viene de un JSON y no tiene origen; '
        'créala con LiveImage.asset, .network, .file o .memory.',
      );
  }
}

/// Carga todas las imágenes del [layout], cada una con su límite de reducción.
Future<List<LiveImagePayload>> loadLayoutImages(
  LiveLayout layout, {
  LiveImageReader reader = defaultImageReader,
}) async {
  final limits = imageLimits(layout);
  return Future.wait([
    for (final img in layout.images)
      () async {
        final Uint8List bytes;
        try {
          bytes = await reader(img);
        } catch (e) {
          throw LiveIslandException(
            'image_failed',
            'No se pudo leer la imagen "${img.key}": $e',
          );
        }
        final l = limits[img.id]!;
        return LiveImagePayload(
          id: img.id,
          bytes: bytes,
          maxWidth: l.maxWidth,
          maxHeight: l.maxHeight,
        );
      }(),
  ]);
}
