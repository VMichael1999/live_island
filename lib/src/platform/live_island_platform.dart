import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';

/// Una imagen lista para enviar al dispositivo, con el límite al que debe
/// reducirse (en píxeles).
class LiveImagePayload {
  const LiveImagePayload({
    required this.id,
    required this.bytes,
    required this.maxWidth,
    required this.maxHeight,
  });

  final String id;
  final Uint8List bytes;
  final int maxWidth, maxHeight;

  Map<String, Object?> toMap() => {
    'id': id,
    'bytes': bytes,
    'maxWidth': maxWidth,
    'maxHeight': maxHeight,
  };
}

/// Cómo se descarta una actividad al terminar.
class LiveDismiss {
  const LiveDismiss._(this.type, this.after);

  /// Desaparece de inmediato.
  static const immediate = LiveDismiss._('immediate', Duration.zero);

  /// Se queda hasta que el usuario la descarta o pasan unas horas (iOS: 4 h).
  static const byDefault = LiveDismiss._('default', Duration.zero);

  /// Se queda visible [delay] con su último estado y luego desaparece
  /// (iOS la limita a 4 horas).
  const LiveDismiss.after(Duration delay) : this._('after', delay);

  final String type;
  final Duration after;
}

/// Error de la plataforma al manejar una actividad.
class LiveIslandException implements Exception {
  const LiveIslandException(this.code, this.message);

  /// `unsupported`, `disabled`, `not_configured`, `not_found`, `start_failed`…
  final String code;
  final String message;

  @override
  String toString() => 'LiveIslandException($code): $message';
}

/// Lo que cada plataforma (iOS, Android) implementa.
abstract class LiveIslandPlatform {
  /// ¿Esta plataforma necesita los PNG de `LiveIcon.android`? (Solo Android.)
  bool get needsAndroidIcons;

  /// ¿Puede la app mostrar actividades? (iOS: `areActivitiesEnabled`;
  /// Android: notificaciones permitidas y, en Android 16+, promovidas.)
  Future<bool> areEnabled();

  /// Pide el permiso de notificaciones (Android 13+). En iOS no hace nada y
  /// devuelve si las actividades están activas.
  Future<bool> requestPermission();

  /// Abre los ajustes donde el usuario permite las notificaciones promovidas
  /// a Live Update (Android 16+). Devuelve `false` si no existen.
  Future<bool> openPromotionSettings();

  /// Inicia una actividad y devuelve su id.
  Future<String> start({
    required String layoutJson,
    required String stateJson,
    required List<LiveImagePayload> images,
    String? deepLink,
    Duration? staleAfter,
    double relevance = 0,
  });

  Future<void> update(String id, String stateJson, {Duration? staleAfter});

  Future<void> end(
    String id, {
    String? stateJson,
    LiveDismiss dismiss = LiveDismiss.byDefault,
  });
}

/// Implementación por canal de métodos (`live_island`).
class MethodChannelLiveIslandPlatform implements LiveIslandPlatform {
  MethodChannelLiveIslandPlatform([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('live_island');

  final MethodChannel _channel;

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw LiveIslandException(e.code, e.message ?? e.code);
    } on MissingPluginException {
      throw const LiveIslandException(
        'unsupported',
        'live_island todavía no está disponible en esta plataforma.',
      );
    }
  }

  @override
  bool get needsAndroidIcons => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> areEnabled() async => await _call<bool>('areEnabled') ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _call<bool>('requestPermission') ?? false;

  @override
  Future<bool> openPromotionSettings() async =>
      await _call<bool>('openPromotionSettings') ?? false;

  @override
  Future<String> start({
    required String layoutJson,
    required String stateJson,
    required List<LiveImagePayload> images,
    String? deepLink,
    Duration? staleAfter,
    double relevance = 0,
  }) async {
    final id = await _call<String>('start', {
      'layout': layoutJson,
      'state': stateJson,
      'images': [for (final i in images) i.toMap()],
      'deepLink': deepLink,
      'staleAfter':
          staleAfter?.inMilliseconds == null
              ? null
              : staleAfter!.inMilliseconds / 1000,
      'relevance': relevance,
    });
    if (id == null) {
      throw const LiveIslandException(
        'start_failed',
        'La plataforma no devolvió un id.',
      );
    }
    return id;
  }

  @override
  Future<void> update(String id, String stateJson, {Duration? staleAfter}) =>
      _call<void>('update', {
        'id': id,
        'state': stateJson,
        'staleAfter':
            staleAfter == null ? null : staleAfter.inMilliseconds / 1000,
      });

  @override
  Future<void> end(
    String id, {
    String? stateJson,
    LiveDismiss dismiss = LiveDismiss.byDefault,
  }) => _call<void>('end', {
    'id': id,
    'state': stateJson,
    'dismiss': dismiss.type,
    'dismissAfter': dismiss.after.inMilliseconds / 1000,
  });
}
