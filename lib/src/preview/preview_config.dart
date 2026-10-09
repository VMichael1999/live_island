import 'dart:async';
import 'dart:ui' show Brightness;

import 'package:flutter/widgets.dart';

import '../core/layout.dart';
import '../core/state.dart';

/// Construye el glifo de un SF Symbol que la vista previa no trae dibujado.
typedef LiveSymbolBuilder =
    Widget Function(String symbol, double size, Color color);

/// Todo lo que la vista previa necesita para dibujar una actividad.
class LivePreviewConfig {
  LivePreviewConfig({
    required this.layout,
    required Map<String, Object?> state,
    this.now,
    this.images = const {},
    this.brightness = Brightness.dark,
    this.appName = 'Mi app',
    this.androidPromotable = true,
    this.symbolBuilder,
    this.blur = true,
  }) : state = LiveState.normalize(state);

  final LiveLayout layout;

  /// Estado ya normalizado (fechas en ISO 8601 UTC).
  final Map<String, Object?> state;

  /// Instante fijo para contadores. Con `null` la vista previa corre en vivo.
  final DateTime? now;

  /// Imágenes por id de `LiveImage`. Las que falten se leen de su origen
  /// (asset, red, archivo o memoria).
  final Map<String, ImageProvider> images;

  /// Con [Brightness.light] la tarjeta de bloqueo `system` y la notificación de
  /// Android usan sus versiones claras. La isla siempre es negra.
  final Brightness brightness;

  /// Nombre de la app en el encabezado de la notificación de Android.
  final String appName;

  /// `false` para casos que Android no promueve a Live Update.
  final bool androidPromotable;

  /// Dibuja los SF Symbols que no vienen incluidos en la vista previa.
  final LiveSymbolBuilder? symbolBuilder;

  /// Desenfoca el fondo de la tarjeta de bloqueo (`BackdropFilter`). Apágalo si
  /// tu GPU lo rechaza (por ejemplo, Impeller con OpenGL ES en algunos emuladores).
  final bool blur;
}

/// Entrega la hora actual a [builder]; si [fixed] es `null` se actualiza cada
/// segundo para que las cuentas regresivas corran.
class LivePreviewClock extends StatefulWidget {
  const LivePreviewClock({super.key, this.fixed, required this.builder});

  final DateTime? fixed;
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<LivePreviewClock> createState() => _LivePreviewClockState();
}

class _LivePreviewClockState extends State<LivePreviewClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(LivePreviewClock old) {
    super.didUpdateWidget(old);
    if ((old.fixed == null) != (widget.fixed == null)) _sync();
  }

  void _sync() {
    _timer?.cancel();
    _timer =
        widget.fixed != null
            ? null
            : Timer.periodic(const Duration(seconds: 1), (_) {
              if (mounted) setState(() {});
            });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, (widget.fixed ?? DateTime.now()).toUtc());
}
