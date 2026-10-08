import 'dart:convert';

import 'core/check.dart';
import 'core/layout.dart';
import 'core/state.dart';
import 'platform/image_loader.dart';
import 'platform/live_island_platform.dart';

/// Una actividad en curso. Se obtiene con [LiveIsland.start].
class LiveActivity {
  LiveActivity._(this.id, this._platform);

  /// Identificador de la plataforma (ActivityKit en iOS).
  final String id;
  final LiveIslandPlatform _platform;

  /// Cambia solo los campos indicados; el resto del estado se conserva. Es lo
  /// único que viaja en cada actualización (iOS limita a 4 096 bytes).
  Future<void> update(Map<String, Object?> state, {Duration? staleAfter}) =>
      _platform.update(
        id,
        jsonEncode(LiveState.normalize(state)),
        staleAfter: staleAfter,
      );

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

  /// Reemplaza la plataforma (para pruebas). Con `null` vuelve a la real.
  static void debugOverride({
    LiveIslandPlatform? platform,
    LiveImageReader? imageReader,
  }) {
    _platform = platform ?? MethodChannelLiveIslandPlatform();
    _imageReader = imageReader ?? defaultImageReader;
  }

  /// ¿Puede la app mostrar actividades ahora? En iOS es
  /// `ActivityAuthorizationInfo.areActivitiesEnabled`.
  static Future<bool> areEnabled() => _platform.areEnabled();

  /// Inicia una actividad con su [layout] (que viaja una sola vez) y su
  /// estado inicial [state].
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
  }) async {
    final normalized = LiveState.normalize(state);
    final report = check(layout, normalized, androidPromotable: true);
    final blocking = report.items.where(
      (c) => c.code == 'statePayload' && c.severity == LiveSeverity.bad,
    );
    if (blocking.isNotEmpty) {
      throw StateError(blocking.first.message);
    }
    final images = await loadLayoutImages(layout, reader: _imageReader);
    final id = await _platform.start(
      layoutJson: jsonEncode(layout.toJson()),
      stateJson: jsonEncode(normalized),
      images: images,
      deepLink: deepLink,
      staleAfter: staleAfter,
      relevance: relevance,
    );
    return LiveActivity._(id, _platform);
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
