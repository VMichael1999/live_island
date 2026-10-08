import 'core/check.dart';
import 'core/layout.dart';

/// Punto de entrada del paquete.
abstract final class LiveIsland {
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
