// Diseños de viaje de la app «Run»: llegada, viaje detallado y, más adelante,
// código PIN, destino, parada previa y pedido a domicilio.
//
// Mismas reglas que `designs.dart`: cada uno es un `LivePreset` normal, la isla
// es negra, la tarjeta de bloqueo es propia y las barras terminan en un marcador
// pegado con el auto encima.
import 'dart:ui' show Color;

import '../components/layout_nodes.dart';
import '../components/progress.dart';
import '../components/text.dart';
import '../components/visuals.dart';
import '../core/bind.dart';
import '../core/enums.dart';
import '../core/layout.dart';
import '../core/node.dart';
import 'designs.dart';
import 'preset.dart';

const _white = Color(0xFFFFFFFF);
const _soft = Color(0xFFB9BDD0);

LiveNode _field(
  String field, {
  double? size,
  int? weight,
  Color? color,
  int? lines,
  LiveAlign? align,
}) => LiveText(
  LiveBind(field),
  size: size,
  weight: weight,
  color: color,
  lines: lines,
  align: align,
);

/// Placa dentro de un recuadro con borde.
LiveNode _plate(String field, {Color color = _white}) => LiveBox(
  border: color,
  borderWidth: 1,
  radius: 5,
  child: LivePadding(
    _field(field, size: 12, weight: 600, color: color, lines: 1),
    horizontal: 6,
    vertical: 1,
  ),
);

/// Auto con el que avanza la barra, visto desde arriba.
LiveTracker _tracker(LiveImage? image) => LiveTracker(
  image ??
      LiveImage.asset(
        liveDesignCarTopAsset,
        width: 88,
        height: 46,
        shape: LiveShape.square,
      ),
  height: 26,
  background: LiveTrackerBackground.none,
);

/// Llegada: a qué hora llegarás y cuánto pagas, sin barra. Datos: `hora`,
/// `pago`, `placa`.
///
/// Es la versión más simple de un viaje en curso: marca y auto con su placa
/// arriba, la hora de llegada a la izquierda y el pago a la derecha.
final class RideArrivalPreset extends LivePreset {
  const RideArrivalPreset({
    this.accent = const Color(0xFF6FA8FF),
    this.background = const Color(0xFF0B1B3F),
    this.brand = 'Run',
    this.carImage,
    this.compactIcon,
    this.chip,
  });

  /// Color del monto.
  final Color accent;

  /// Fondo de la tarjeta de bloqueo (azul oscuro).
  final Color background;

  /// Nombre de la app, arriba a la izquierda de la tarjeta.
  final String brand;

  /// Imagen del auto, sin fondo. Por defecto es un sedán con su placa ya
  /// dibujada; con una imagen propia la placa sale del campo `placa`.
  final LiveImage? carImage;

  /// Ícono o imagen de la isla compacta y la mínima (por defecto un auto).
  final LiveVisual? compactIcon;

  /// Chip de Android; por defecto el monto.
  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'ride_arrival',
    appName: brand,
    accent: accent,
    icon: presetIcon('car.fill', 'car'),
    countdown: false,
    progress: PresetProgress.none,
    buttons: const [],
    chip: chip ?? const LiveChip.text('S/14'),
    sample: const PresetSample(
      title: 'Llegarás a las 11:36 AM',
      subtitle: 'Pago S/ 14',
      name: 'Run',
      highlight: 'S/ 14',
      progress: 0,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'hora': '11:36 AM',
    'pago': 'S/ 14',
    'placa': 'CSB488',
  };

  LiveVisual get _compact =>
      compactIcon ?? presetIcon('car.fill', 'car', accent: true);

  /// Con la imagen por defecto la placa ya viene dibujada; con una imagen
  /// propia se dibuja la placa del estado (`placa`) debajo del auto.
  LiveNode get _carWithPlate =>
      carImage == null
          ? LiveImage.asset(
            liveDesignCarPlateAsset,
            width: 560,
            height: 258,
            shape: LiveShape.square,
          ).withHeight(54)
          : LiveColumn(
            [carImage!.withHeight(30), _plate('placa')],
            gap: 1,
            align: LiveAlign.end,
          );

  LiveNode get _brand =>
      LiveText.literal(brand, size: 24, weight: 800, color: _white);

  /// Hora de llegada a la izquierda y pago a la derecha.
  LiveNode get _arrivalRow => LiveRow([
    LiveColumn([
      LiveText.literal(
        'Llegarás aproximadamente',
        size: 18,
        weight: 600,
        color: _white,
        lines: 1,
      ),
      LiveText.format(
        'a las {hora}',
        size: 18,
        weight: 600,
        color: _white,
        lines: 1,
      ),
    ], gap: 2),
    const LiveSpacer(),
    LiveColumn([
      LiveText.literal('Pago', size: 18, weight: 600, color: _white),
      _field('pago', size: 24, weight: 800, color: accent, lines: 1),
    ], align: LiveAlign.end),
  ], align: LiveAlign.end);

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent),
    appLogo: presetIcon('car.fill', 'car'),
    compactLeading: _compact,
    compactTrailing: _field('pago', size: 15, weight: 700, color: accent),
    minimal: _compact,
    // La marca y el auto van junto al sensor; el texto y el pago, abajo, en una
    // sola pieza a todo el ancho: el pago nunca se corta.
    expanded: LiveExpanded(
      // 6 pt a cada lado para alinear con el texto de abajo.
      leading: LivePadding(_brand, horizontal: 6),
      trailing: LivePadding(_carWithPlate, horizontal: 6),
      bottom: _arrivalRow,
    ),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: background,
        radius: 22,
        child: LivePadding(
          LiveColumn([
            LiveRow([
              _brand,
              const LiveSpacer(),
              _carWithPlate,
            ], align: LiveAlign.start),
            _arrivalRow,
          ], gap: 6),
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    android: LiveAndroid(
      title: const LiveText.format('Llegarás a las {hora}'),
      text: const LiveText.format('Pago {pago} · {placa}'),
      chip: chip ?? const LiveChip.text('S/14'),
    ),
  );
}

/// Viaje en curso con detalle: fase, destino, dirección, categoría y pago, con
/// una barra que termina en un cuadrado. Datos: `fase`, `hora`, `direccion`,
/// `categoria`, `pago`, `progreso`.
///
/// `fase` cambia con lo que llegue del servidor («EN CAMINO AL DESTINO»,
/// «EL CONDUCTOR LLEGÓ»…) sin cambiar el diseño.
final class RideTripPreset extends LivePreset {
  const RideTripPreset({
    this.accent = const Color(0xFFB794FF),
    this.background = const Color(0xFF1B1230),
    this.brand = 'Run',
    this.driverInitials = 'A',
    this.driverPhoto,
    this.trackerImage,
    this.compactIcon,
    this.chip,
  });

  /// Color de la fase, del monto y de lo avanzado.
  final Color accent;

  /// Fondo de la tarjeta de bloqueo (morado oscuro).
  final Color background;

  /// Nombre de la app.
  final String brand;

  /// Iniciales del conductor (si no hay [driverPhoto]).
  final String driverInitials;

  /// Foto circular del conductor.
  final LiveImage? driverPhoto;

  /// Auto que avanza sobre la barra (vista desde arriba, sin fondo).
  final LiveImage? trackerImage;

  /// Ícono o imagen de la isla compacta y la mínima (por defecto un auto).
  final LiveVisual? compactIcon;

  /// Chip de Android; por defecto «En ruta».
  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'ride_trip',
    appName: brand,
    accent: accent,
    icon: presetIcon('car.fill', 'car'),
    countdown: false,
    progress: PresetProgress.bar,
    buttons: const [],
    chip: chip ?? const LiveChip.text('En ruta'),
    sample: const PresetSample(
      title: 'Destino 2:44 PM',
      subtitle: 'Av. Javier Prado Este, Santiago de Surco',
      name: 'Ana',
      highlight: 'S/ 13.60',
      progress: 0.32,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'fase': 'EN CAMINO AL DESTINO',
    'hora': '2:44 PM',
    'direccion': 'Av. Javier Prado Este, Santiago de Surco',
    'categoria': 'ECONÓMICO',
    'pago': 'S/ 13.60',
    'progreso': 0.32,
  };

  LiveVisual get _compact =>
      compactIcon ?? presetIcon('car.fill', 'car', accent: true);

  LiveVisual get _driver =>
      driverPhoto != null
          ? LiveAvatar.photo(driverPhoto!, size: 46)
          : LiveAvatar(driverInitials, size: 46);

  LiveNode get _bar => LiveProgress.bar(
    value: const LiveBind('progreso'),
    tracker: _tracker(trackerImage),
    style: LiveProgressStyle(
      height: 4,
      color: _white,
      trackColor: const Color(0xFF5A5470),
      endMarker: LivePointShape.targetSquare,
      pointSize: 16,
      pointColor: accent,
    ),
  );

  LiveNode get _pill => LiveBox(
    tint: .18,
    radius: 9,
    child: LivePadding(
      _field('fase', size: 12, weight: 700, color: accent, lines: 1),
      horizontal: 10,
      vertical: 4,
    ),
  );

  /// Destino con dirección a la izquierda, categoría con pago a la derecha y
  /// debajo la barra. La dirección es lo que se corta con «…», nunca el pago.
  LiveNode get _tripBody => LiveColumn([
    LiveRow([
      _driver,
      LiveColumn([
        LiveText.format(
          'Destino {hora}',
          size: 19,
          weight: 700,
          color: _white,
          lines: 1,
        ),
        _field('direccion', size: 13, color: _soft, lines: 1),
      ], gap: 2),
      const LiveSpacer(),
      LiveColumn(
        [
          _field('categoria', size: 11, color: _soft, lines: 1),
          _field('pago', size: 20, weight: 800, color: _white, lines: 1),
        ],
        gap: 2,
        align: LiveAlign.end,
      ),
    ], gap: 10),
    _bar,
  ], gap: 8);

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent),
    appLogo: presetIcon('car.fill', 'car'),
    compactLeading: _compact,
    compactTrailing: _field('hora', size: 14, weight: 700, color: accent),
    minimal: _compact,
    // La fase va junto al sensor y el resto abajo, a todo el ancho.
    expanded: LiveExpanded(center: _pill, bottom: _tripBody),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: background,
        radius: 22,
        child: LivePadding(
          LiveColumn([
            LiveRow([_pill, const LiveSpacer()]),
            _tripBody,
          ], gap: 10),
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    android: LiveAndroid(
      title: const LiveText.format('Destino {hora}'),
      text: const LiveText.format('{direccion}'),
      chip: chip ?? const LiveChip.text('En ruta'),
    ),
  );
}
