import 'dart:async';
import 'dart:convert';

import 'core/check.dart';
import 'core/layout.dart';
import 'core/state.dart';
import 'platform/image_loader.dart';
import 'platform/live_island_platform.dart';

/// Una actividad en curso. Se obtiene con [LiveIsland.start].
class LiveActivity {
  LiveActivity._(this.id, this._platform, {this.customId});

  /// Identificador de la plataforma (ActivityKit en iOS).
  final String id;

  /// El id propio que la app dio en [LiveIsland.start] (`customId`), si lo hay.
  final String? customId;
  final LiveIslandPlatform _platform;

  /// Cambia solo los campos indicados; el resto del estado se conserva. Es lo
  /// único que viaja en cada actualización (iOS limita a 4 096 bytes).
  ///
  /// [staleAfter] marca el contenido como desactualizado pasado ese tiempo
  /// (ver [LiveBind.stale]). [alert] llama la atención: expande la isla y suena
  /// en iOS; en Android la notificación suena y aparece como aviso emergente.
  Future<void> update(
    Map<String, Object?> state, {
    Duration? staleAfter,
    LiveAlert? alert,
  }) => _platform.update(
    id,
    jsonEncode(LiveState.normalize(state)),
    staleAfter: staleAfter,
    alert: alert,
  );

  /// Mantiene la actividad al día con una fuente de datos en vivo: la posición
  /// del conductor, el estado de un pedido, un temporizador… Cada evento de
  /// [source] pasa por [toState] y el resultado se envía con [update].
  ///
  /// Para no gastar el presupuesto de actualizaciones del sistema, envía como
  /// máximo una cada [minInterval] (la última siempre llega) y se salta las que
  /// no cambian nada. Devuelve la suscripción: cancélala (o llama a [end]) para
  /// dejar de seguir.
  ///
  /// ```dart
  /// actividad.follow(
  ///   posiciones, // Stream<LiveLatLng> de tu mapa o de tu servidor
  ///   (p) => {'progreso': ruta.progressAt(p), 'etapa': ruta.stageAt(p, 4)},
  /// );
  /// ```
  StreamSubscription<T> follow<T>(
    Stream<T> source,
    Map<String, Object?> Function(T event) toState, {
    Duration minInterval = const Duration(seconds: 5),
  }) {
    Map<String, Object?>? last;
    Map<String, Object?>? pending;
    Timer? timer;
    DateTime? sentAt;

    Future<void> flush() async {
      timer = null;
      final next = pending;
      pending = null;
      if (next == null) return;
      sentAt = DateTime.now();
      last = {...?last, ...next};
      await update(next);
    }

    final sub = source.listen((event) {
      final next = toState(event);
      final merged = {...?pending, ...next};
      final base = {...?last};
      if (merged.entries.every(
        (e) => base.containsKey(e.key) && base[e.key] == e.value,
      )) {
        return;
      }
      pending = merged;
      final wait =
          sentAt == null
              ? Duration.zero
              : minInterval - DateTime.now().difference(sentAt!);
      if (wait <= Duration.zero) {
        timer?.cancel();
        flush();
      } else {
        timer ??= Timer(wait, flush);
      }
    }, onDone: () => timer?.cancel());
    return sub;
  }

  /// Tokens de push de esta actividad (iOS; empiezan a llegar poco después
  /// de [LiveIsland.start] con `requestPushToken: true`). Envíalos a tu
  /// servidor para actualizarla o terminarla por APNs.
  Stream<String> get pushTokens => _platform.pushEvents
      .where((e) => e is LivePushTokenEvent && e.token.activityId == id)
      .map((e) => (e as LivePushTokenEvent).token.token);

  /// Programa que la actividad desaparezca a las [at].
  ///
  /// El comportamiento depende de la plataforma, porque ActivityKit no tiene
  /// «terminar más tarde» para una actividad viva:
  ///
  /// - **iOS:** la actividad **termina ya** (sale de la isla y no se puede
  ///   actualizar más) y la tarjeta de la pantalla de bloqueo se queda con
  ///   [state] hasta [at]; iOS la quita como mucho 4 horas después.
  /// - **Android:** la notificación **sigue viva y se puede actualizar**, y el
  ///   sistema la retira solo a las [at], aunque la app esté cerrada.
  ///
  /// Si [at] ya pasó, termina de inmediato.
  Future<void> scheduleEnd(DateTime at, {Map<String, Object?>? state}) {
    final wait = at.difference(DateTime.now());
    if (wait <= Duration.zero) {
      return end(state: state, dismiss: LiveDismiss.immediate);
    }
    return _platform.scheduleEnd(
      id,
      secondsFromNow: wait.inMilliseconds / 1000,
      stateJson: state == null ? null : jsonEncode(LiveState.normalize(state)),
    );
  }

  /// Termina la actividad. Con [state] deja un último estado visible.
  Future<void> end({
    Map<String, Object?>? state,
    LiveDismiss dismiss = LiveDismiss.byDefault,
  }) => _platform.end(
    id,
    stateJson: state == null ? null : jsonEncode(LiveState.normalize(state)),
    dismiss: dismiss,
  );
}

/// Punto de entrada del paquete.
abstract final class LiveIsland {
  static LiveIslandPlatform _platform = MethodChannelLiveIslandPlatform();
  static LiveImageReader _imageReader = defaultImageReader;
  static LiveAssetReader _assetReader = defaultAssetReader;

  /// Reemplaza la plataforma (para pruebas). Con `null` vuelve a la real.
  static void debugOverride({
    LiveIslandPlatform? platform,
    LiveImageReader? imageReader,
    LiveAssetReader? assetReader,
  }) {
    _platform = platform ?? MethodChannelLiveIslandPlatform();
    _imageReader = imageReader ?? defaultImageReader;
    _assetReader = assetReader ?? defaultAssetReader;
  }

  /// ¿Puede la app mostrar actividades ahora? En iOS es
  /// `ActivityAuthorizationInfo.areActivitiesEnabled`.
  static Future<bool> areEnabled() => _platform.areEnabled();

  /// Pide el permiso de notificaciones (Android 13 o superior). Llámalo antes
  /// de [start]; si el usuario lo rechaza, [start] lanza `disabled`. En iOS
  /// no hace nada.
  static Future<bool> requestPermission() => _platform.requestPermission();

  /// Abre los ajustes donde el usuario permite que la app publique Live
  /// Updates (Android 16 o superior). Devuelve `false` si no existen.
  static Future<bool> openPromotionSettings() =>
      _platform.openPromotionSettings();

  /// Las actividades que siguen vivas, por ejemplo tras reabrir la app o
  /// cuando una acción llegó con la app cerrada, para poder actualizarlas.
  static Future<List<LiveActivity>> activeActivities() async => [
    for (final a in await _platform.activeActivities())
      LiveActivity._(a.id, _platform, customId: a.customId),
  ];

  /// La actividad viva que se inició con [customId], o `null` si no existe
  /// (ya terminó o el usuario la descartó). Sirve tras reabrir la app, sin
  /// guardar el id de la plataforma.
  static Future<LiveActivity?> activity(String customId) async {
    for (final a in await _platform.activeActivities()) {
      if (a.customId == customId) {
        return LiveActivity._(a.id, _platform, customId: customId);
      }
    }
    return null;
  }

  /// Termina todas las actividades vivas de la app (por ejemplo al cerrar
  /// sesión). Con [dismiss] `immediate` desaparecen de inmediato.
  static Future<void> endAll({LiveDismiss dismiss = LiveDismiss.immediate}) =>
      _platform.endAll(dismiss: dismiss);

  /// Cada vez que el usuario toca un botón de una actividad llega aquí su
  /// `id` (el de `LiveButton(id: ...)`). Las acciones que ocurrieron con la
  /// app cerrada se entregan al empezar a escuchar.
  static Stream<String> get actions => _platform.actions;

  /// Atajo de [actions]: llama a [callback] con el id de cada botón tocado.
  /// Cancela la suscripción devuelta cuando ya no la necesites.
  static StreamSubscription<String> onAction(
    void Function(String id) callback,
  ) => _platform.actions.listen(callback);

  /// Textos que el usuario escribe en los botones de respuesta en línea
  /// (`LiveButton.reply`), con el `id` del botón. Solo Android: en iOS esos
  /// botones llegan por [actions], sin texto.
  static Stream<LiveReply> get replies => _platform.replies;

  /// Atajo de [replies]: llama a [callback] con el botón y el texto escrito.
  static StreamSubscription<LiveReply> onReply(
    void Function(String id, String text) callback,
  ) => _platform.replies.listen((r) => callback(r.id, r.text));

  /// Tokens de push de iOS: los de cada actividad (con `requestPushToken`) y
  /// el de push-to-start (iOS 17.2), que no tiene `activityId`.
  static Stream<LivePushToken> get pushTokens => _platform.pushEvents
      .where((e) => e is LivePushTokenEvent)
      .map((e) => (e as LivePushTokenEvent).token);

  /// Actividades que empezaron por un push (push-to-start en iOS; [handlePush]
  /// con `event: start` en Android).
  static Stream<LiveActivity> get startedByPush => _platform.pushEvents
      .where((e) => e is LivePushStartedEvent)
      .map(
        (e) =>
            LiveActivity._((e as LivePushStartedEvent).activityId, _platform),
      );

  /// Guarda [layout] en el dispositivo con el nombre [name]. Una actividad
  /// iniciada desde un push usa ese diseño por su nombre, porque un push no
  /// puede llevar el diseño. Vuelve a llamarlo si el diseño cambia.
  static Future<void> registerLayout(String name, LiveLayout layout) async {
    final images = await loadLayoutImages(
      layout,
      reader: _imageReader,
      androidIcons: _platform.needsAndroidIcons,
      assetReader: _assetReader,
    );
    await _platform.registerLayout(
      name: name,
      layoutJson: jsonEncode(layout.toJson()),
      images: images,
    );
  }

  /// Procesa los datos de un mensaje de FCM (Android) para iniciar, actualizar
  /// o terminar una actividad; ver `docs/push.md`. Llámalo desde tu handler de
  /// `firebase_messaging`. Devuelve el id de la actividad afectada. En iOS no
  /// hace nada: APNs llega directo a ActivityKit.
  static Future<String?> handlePush(Map<String, Object?> data) =>
      _platform.handlePush(data);

  /// Inicia una actividad con su [layout] (que viaja una sola vez) y su
  /// estado inicial [state].
  ///
  /// [customId] es un id propio de tu app (`'viaje-42'`). Si ya hay una
  /// actividad viva con ese id, no se crea otra: se actualiza su estado y se
  /// devuelve la misma. Después se encuentra con [activity].
  ///
  /// [deepLink] se abre al tocar la actividad. [staleAfter] marca el contenido
  /// como desactualizado pasado ese tiempo. Lanza [LiveIslandException] si la
  /// plataforma no puede (`disabled`, `not_configured`…) y [StateError] si el
  /// diseño tiene errores según [check].
  static Future<LiveActivity> start({
    required LiveLayout layout,
    required Map<String, Object?> state,
    String? deepLink,
    Duration? staleAfter,
    double relevance = 0,
    bool requestPushToken = false,
    String? customId,
  }) async {
    if (customId != null && customId.isEmpty) {
      throw ArgumentError.value(customId, 'customId', 'No puede estar vacío');
    }
    final normalized = LiveState.normalize(state);
    final report = check(layout, normalized, androidPromotable: true);
    final blocking = report.items.where(
      (c) => c.code == 'statePayload' && c.severity == LiveSeverity.bad,
    );
    if (blocking.isNotEmpty) {
      throw StateError(blocking.first.message);
    }
    final images = await loadLayoutImages(
      layout,
      reader: _imageReader,
      androidIcons: _platform.needsAndroidIcons,
      assetReader: _assetReader,
    );
    final id = await _platform.start(
      layoutJson: jsonEncode(layout.toJson()),
      stateJson: jsonEncode(normalized),
      images: images,
      deepLink: deepLink,
      staleAfter: staleAfter,
      relevance: relevance,
      requestPushToken: requestPushToken,
      customId: customId,
    );
    return LiveActivity._(id, _platform, customId: customId);
  }

  /// Valida [layout] con [state] con el mismo criterio del panel "Validación"
  /// del HTML de prototipos (`docs/design/live_island_prototipos.html`).
  ///
  /// [androidPromotable] debe ser `false` para casos que Google no promueve a
  /// Live Update (publicidad, chats, actividades que no inició el usuario).
  static LiveReport check(
    LiveLayout layout,
    Map<String, Object?> state, {
    DateTime? now,
    bool androidPromotable = true,
  }) => checkLayout(
    layout,
    state,
    now: now,
    androidPromotable: androidPromotable,
  );
}
