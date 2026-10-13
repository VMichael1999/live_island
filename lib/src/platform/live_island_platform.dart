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

/// Un token de push de iOS (ActivityKit).
class LivePushToken {
  const LivePushToken({required this.token, this.activityId});

  /// Token en hexadecimal, listo para enviarlo al servidor.
  final String token;

  /// Actividad a la que pertenece. `null` = token de push-to-start (iOS 17.2),
  /// que sirve para iniciar actividades desde el servidor.
  final String? activityId;

  bool get isPushToStart => activityId == null;

  @override
  String toString() =>
      'LivePushToken(${activityId ?? 'push-to-start'}: $token)';
}

/// Eventos que la plataforma envía sobre push.
sealed class LivePushEvent {
  const LivePushEvent();
}

/// Llegó un token nuevo (de una actividad o de push-to-start).
class LivePushTokenEvent extends LivePushEvent {
  const LivePushTokenEvent(this.token);
  final LivePushToken token;
}

/// Una actividad empezó por push (iOS push-to-start, Android `handlePush`).
class LivePushStartedEvent extends LivePushEvent {
  const LivePushStartedEvent(this.activityId);
  final String activityId;
}

/// Un aviso que acompaña a una actualización: en iOS la isla se expande un
/// momento (o aparece un banner en la pantalla de bloqueo) con [title] y
/// [body], y suena; en Android la notificación suena y aparece como aviso
/// emergente.
///
/// ```dart
/// await actividad.update(
///   {'estado': 'llegó'},
///   alert: const LiveAlert(title: 'Tu conductor llegó', body: 'Toyota Yaris · ABC-123'),
/// );
/// ```
class LiveAlert {
  const LiveAlert({required this.title, required this.body, this.sound});

  /// Título del aviso (iOS). Android muestra el contenido de la actividad.
  final String title;

  /// Texto del aviso (iOS).
  final String body;

  /// Nombre de un archivo de sonido del paquete de la app (`aviso.caf`).
  /// Con `null` suena el sonido por defecto.
  final String? sound;

  Map<String, Object?> toMap() => {
    'title': title,
    'body': body,
    if (sound != null) 'sound': sound,
  };

  @override
  bool operator ==(Object other) =>
      other is LiveAlert &&
      other.title == title &&
      other.body == body &&
      other.sound == sound;

  @override
  int get hashCode => Object.hash(title, body, sound);
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

/// Una actividad viva: su id de la plataforma y, si la app se lo dio al
/// iniciarla, su id propio.
class LiveActivityInfo {
  const LiveActivityInfo(this.id, {this.customId});

  final String id;
  final String? customId;

  @override
  bool operator ==(Object other) =>
      other is LiveActivityInfo && other.id == id && other.customId == customId;

  @override
  int get hashCode => Object.hash(id, customId);
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

  /// Las actividades que siguen vivas (también las iniciadas antes de que la
  /// app se cerrara o por un push), con su id propio si lo tienen.
  Future<List<LiveActivityInfo>> activeActivities();

  /// Termina todas las actividades vivas de la app.
  Future<void> endAll({LiveDismiss dismiss = LiveDismiss.immediate});

  /// Id de cada botón que el usuario toca en la actividad. Las acciones que
  /// llegaron con la app cerrada se entregan al empezar a escuchar.
  Stream<String> get actions;

  /// Tokens de push y actividades iniciadas por push.
  Stream<LivePushEvent> get pushEvents;

  /// Guarda un diseño con nombre en el dispositivo. Hace falta para iniciar
  /// actividades desde un push, que no puede llevar el diseño.
  Future<void> registerLayout({
    required String name,
    required String layoutJson,
    required List<LiveImagePayload> images,
  });

  /// Procesa los datos de un push de FCM (Android). Devuelve el id de la
  /// actividad afectada. En iOS no hace nada: APNs llega directo a ActivityKit.
  Future<String?> handlePush(Map<String, Object?> data);

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
    bool requestPushToken = false,
    String? customId,
  });

  Future<void> update(
    String id,
    String stateJson, {
    Duration? staleAfter,
    LiveAlert? alert,
  });

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
  static const _actionsChannel = EventChannel('live_island/actions');
  static const _pushChannel = EventChannel('live_island/push');

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
  Future<List<LiveActivityInfo>> activeActivities() async => [
    for (final e in await _call<List<Object?>>('activeActivities') ?? const [])
      if (e is Map)
        LiveActivityInfo(
          e['id']! as String,
          customId:
              (e['customId'] as String?)?.isEmpty ?? true
                  ? null
                  : e['customId'] as String?,
        )
      else
        LiveActivityInfo(e! as String),
  ];

  @override
  Future<void> endAll({LiveDismiss dismiss = LiveDismiss.immediate}) =>
      _call<void>('endAll', {
        'dismiss': dismiss.type,
        'dismissAfter': dismiss.after.inMilliseconds / 1000,
      });

  @override
  Stream<String> get actions =>
      _actionsChannel.receiveBroadcastStream().map((e) => e as String);

  @override
  Stream<LivePushEvent> get pushEvents =>
      _pushChannel.receiveBroadcastStream().map((e) {
        final m = Map<String, Object?>.from(e as Map);
        return switch (m['type']) {
          'started' => LivePushStartedEvent(m['activityId']! as String),
          _ => LivePushTokenEvent(
            LivePushToken(
              token: m['token']! as String,
              activityId: m['activityId'] as String?,
            ),
          ),
        };
      });

  @override
  Future<void> registerLayout({
    required String name,
    required String layoutJson,
    required List<LiveImagePayload> images,
  }) => _call<void>('registerLayout', {
    'name': name,
    'layout': layoutJson,
    'images': [for (final i in images) i.toMap()],
  });

  @override
  Future<String?> handlePush(Map<String, Object?> data) =>
      _call<String>('handlePush', {'data': data});

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
    bool requestPushToken = false,
    String? customId,
  }) async {
    final id = await _call<String>('start', {
      'customId': customId,
      'layout': layoutJson,
      'state': stateJson,
      'images': [for (final i in images) i.toMap()],
      'deepLink': deepLink,
      'staleAfter':
          staleAfter?.inMilliseconds == null
              ? null
              : staleAfter!.inMilliseconds / 1000,
      'relevance': relevance,
      'requestPushToken': requestPushToken,
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
  Future<void> update(
    String id,
    String stateJson, {
    Duration? staleAfter,
    LiveAlert? alert,
  }) => _call<void>('update', {
    'id': id,
    'alert': alert?.toMap(),
    'state': stateJson,
    'staleAfter': staleAfter == null ? null : staleAfter.inMilliseconds / 1000,
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
