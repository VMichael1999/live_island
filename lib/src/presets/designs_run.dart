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
        width: 212,
        height: 113,
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
    this.background = const Color(0xFF000000),
    this.brand = 'Run',
    this.carImage,
    this.compactIcon,
    this.chip,
  });

  /// Color del monto.
  final Color accent;

  /// Fondo de toda la tarjeta de bloqueo (negro). El color del diseño está en
  /// el texto: [accent].
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
            LiveRow([_brand, const LiveSpacer(), _carWithPlate]),
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
    this.background = const Color(0xFF000000),
    this.brand = 'Run',
    this.driverInitials = 'A',
    this.driverPhoto,
    this.trackerImage,
    this.compactIcon,
    this.chip,
  });

  /// Color de la fase, del monto y de lo avanzado.
  final Color accent;

  /// Fondo de toda la tarjeta de bloqueo (negro). El color del diseño está en
  /// el texto y la barra: [accent].
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

/// Seguimiento de un pedido a domicilio en cuatro etapas: la tienda lo recibe,
/// lo prepara, el repartidor lo recoge y llega al cliente. Datos: `titulo`,
/// `hora` y `progreso` (0 a 1: 0 recibido, 1/3 preparando, 2/3 en camino, 1
/// entregado).
///
/// Cada etapa tiene su ícono en gris mientras no llega y de color desde que
/// llega; los tramos entre íconos se pintan igual. El título cambia con lo que
/// mande el servidor («Pedido recibido», «Preparando tu pedido»…).
final class DeliveryOrderPreset extends LivePreset {
  const DeliveryOrderPreset({
    this.accent = const Color(0xFFFF8A1F),
    this.brand = 'Run',
    this.compactIcon,
    this.chip,
  });

  /// Color de los tramos ya recorridos y de la hora.
  final Color accent;

  /// Nombre de la app, arriba a la izquierda.
  final String brand;

  /// Ícono de la isla compacta y la mínima (por defecto la mochila de reparto).
  final LiveVisual? compactIcon;

  /// Chip de Android; por defecto «Pedido».
  final LiveChip? chip;

  static const _stages = ['Recibido', 'Preparando', 'En camino', 'Entregado'];
  static const _gray = Color(0xFF4A4A50);

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'delivery_order',
    appName: brand,
    accent: accent,
    icon: presetIcon('shippingbox.fill', 'package'),
    countdown: false,
    progress: PresetProgress.segments,
    buttons: const [],
    chip: chip ?? const LiveChip.text('Pedido'),
    sample: const PresetSample(
      title: 'En camino a tu ubicación',
      subtitle: '9:45 PM Llegada estimada',
      name: 'Run',
      highlight: '9:45 PM',
      progress: 2 / 3,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'titulo': 'En camino a tu ubicación',
    'hora': '9:45 PM',
    'progreso': 2 / 3,
  };

  LiveImage _icon(int stage, bool reached) => LiveImage.asset(
    liveDesignOrderAsset(stage, reached: reached),
    width: 144,
    height: 144,
    shape: LiveShape.square,
  ).withHeight(40);

  LiveVisual get _compact => compactIcon ?? _icon(3, true).withHeight(20);

  LiveNode get _stagesBar => LiveSegments(
    value: const LiveBind('progreso'),
    labels: _stages,
    points: true,
    showLabels: false,
    stageIcons: [
      for (var i = 1; i <= 4; i++)
        LiveStageIcon(pending: _icon(i, false), reached: _icon(i, true)),
    ],
    style: LiveProgressStyle(
      height: 3,
      color: accent,
      trackColor: _gray,
      // Los tramos terminan antes de cada ícono.
      gap: 52,
      pointSize: 40,
    ),
  );

  LiveNode get _brand =>
      LiveText.literal(brand, size: 20, weight: 800, color: _white);

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent),
    appLogo: presetIcon('shippingbox.fill', 'package'),
    compactLeading: _compact,
    compactTrailing: _field('hora', size: 14, weight: 700, color: accent),
    minimal: _compact,
    // La marca y la hora junto al sensor; el título y las etapas abajo, a todo
    // el ancho.
    expanded: LiveExpanded(
      leading: LivePadding(_brand, horizontal: 6),
      trailing: LivePadding(
        _field('hora', size: 15, weight: 700, color: accent, lines: 1),
        horizontal: 6,
      ),
      bottom: LiveColumn([
        _field('titulo', size: 18, weight: 700, color: _white, lines: 1),
        _stagesBar,
      ], gap: 8),
    ),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: const Color(0xFF000000),
        radius: 22,
        child: LivePadding(
          LiveColumn([
            _brand,
            LiveColumn([
              _field('titulo', size: 22, weight: 700, color: _white, lines: 1),
              LiveText.format(
                '{hora} Llegada estimada',
                size: 14,
                color: _soft,
                lines: 1,
              ),
            ], gap: 3),
            _stagesBar,
          ], gap: 10),
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    android: LiveAndroid(
      title: const LiveText.format('{titulo}'),
      text: const LiveText.format('{hora} Llegada estimada'),
      chip: chip ?? const LiveChip.text('Pedido'),
    ),
  );
}

/// Inicio de un viaje con el código PIN que se le dice al conductor: marca y
/// cuatro casillas con el PIN, cuánto falta, a quién esperar y su foto, con la
/// barra del auto hacia el punto de recogida. Datos: `minutos`, `conductor`,
/// `pin1`, `pin2`, `pin3`, `pin4` y `progreso`.
///
/// El PIN va por dígitos (`pin1` a `pin4`) para dibujar una casilla por cada
/// uno; se ve en la isla y en la pantalla de bloqueo aunque la app esté cerrada.
final class RidePinPreset extends LivePreset {
  const RidePinPreset({
    this.accent = const Color(0xFF3B6CFF),
    this.brand = 'Run',
    this.driverInitials = 'M',
    this.driverPhoto,
    this.trackerImage,
    this.compactIcon,
    this.chip,
  });

  /// Color de las casillas del PIN.
  final Color accent;

  /// Nombre de la app, arriba a la izquierda.
  final String brand;

  /// Iniciales del conductor (si no hay [driverPhoto]).
  final String driverInitials;

  /// Foto circular del conductor.
  final LiveImage? driverPhoto;

  /// Auto que avanza sobre la barra (vista desde arriba, sin fondo).
  final LiveImage? trackerImage;

  /// Ícono o imagen de la isla compacta y la mínima (por defecto un auto).
  final LiveVisual? compactIcon;

  /// Chip de Android; por defecto «PIN».
  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'ride_pin',
    appName: brand,
    accent: accent,
    icon: presetIcon('car.fill', 'car'),
    countdown: false,
    progress: PresetProgress.bar,
    buttons: const [],
    chip: chip ?? const LiveChip.text('PIN'),
    sample: const PresetSample(
      title: 'Inicio de viaje en 1 min',
      subtitle: 'Sal ahora para la llegada de MARCO PAREDES',
      name: 'Marco',
      highlight: '0249',
      progress: .86,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'minutos': '1 min',
    'conductor': 'MARCO PAREDES',
    'pin1': '0',
    'pin2': '2',
    'pin3': '4',
    'pin4': '9',
    'progreso': .86,
  };

  LiveVisual get _compact =>
      compactIcon ?? presetIcon('car.fill', 'car', accent: true);

  LiveNode _photo(double size) =>
      driverPhoto != null
          ? LiveAvatar.photo(driverPhoto!, size: size)
          : LiveAvatar(driverInitials, size: size);

  /// Una casilla por dígito del PIN.
  LiveNode _pin(double size) => LiveRow([
    for (final f in const ['pin1', 'pin2', 'pin3', 'pin4'])
      LiveBox(
        size: size,
        radius: size * .26,
        color: accent,
        child: _field(f, size: size * .62, weight: 700, color: _white),
      ),
  ], gap: size * .14);

  LiveNode get _bar => LiveProgress.bar(
    value: const LiveBind('progreso'),
    tracker: _tracker(trackerImage),
    style: LiveProgressStyle(
      height: 4,
      color: _white,
      trackColor: const Color(0xFF6B6E75),
      endMarker: LivePointShape.target,
      pointSize: 16,
      pointColor: const Color(0xFFD9DADF),
    ),
  );

  LiveNode get _walk => LiveIcon.symbol(
    'figure.walk',
    android: presetIcon('person.fill', 'user').android,
    color: _soft,
    size: 20,
  );

  /// «Inicio de viaje en 1 min» y, debajo, a quién esperar.
  LiveNode _text(double titleSize) => LiveColumn([
    LiveText.format(
      'Inicio de viaje en {minutos}',
      size: titleSize,
      weight: 700,
      color: _white,
      lines: 1,
    ),
    LiveRow([
      _walk,
      LiveColumn([
        LiveText.literal(
          'Sal ahora para la llegada de',
          size: 13,
          color: _soft,
          lines: 1,
        ),
        _field('conductor', size: 13, color: _soft, lines: 1),
      ], gap: 0),
    ], gap: 8),
  ], gap: 4);

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent),
    appLogo: presetIcon('car.fill', 'car'),
    compactLeading: _compact,
    compactTrailing: LiveText.format(
      '{pin1}{pin2}{pin3}{pin4}',
      size: 14,
      weight: 700,
      color: _white,
    ),
    minimal: _compact,
    // La marca y el PIN junto al sensor; el resto abajo, a todo el ancho.
    expanded: LiveExpanded(
      leading: LivePadding(
        LiveText.literal(brand, size: 20, weight: 800, color: _white),
        horizontal: 6,
      ),
      // La zona derecha de la isla es angosta: casillas de 20 pt para que quepan
      // los cuatro dígitos.
      trailing: LivePadding(_pin(20), horizontal: 8, vertical: 3),
      bottom: LiveColumn([
        LiveRow([_text(18), const LiveSpacer(), _photo(46)]),
        _bar,
      ], gap: 8),
    ),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: const Color(0xFF000000),
        radius: 22,
        child: LivePadding(
          LiveColumn([
            LiveRow([
              LiveText.literal(brand, size: 22, weight: 800, color: _white),
              const LiveSpacer(),
              _pin(30),
            ]),
            LiveRow([_text(21), const LiveSpacer(), _photo(52)]),
            _bar,
          ], gap: 8),
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    android: LiveAndroid(
      title: const LiveText.format('Inicio de viaje en {minutos}'),
      text: const LiveText.format('Tu PIN: {pin1}{pin2}{pin3}{pin4}'),
      chip: chip ?? const LiveChip.text('PIN'),
    ),
  );
}

/// El conductor aún tiene que dejar a otro pasajero antes de venir por ti:
/// cuánto falta, el auto con su placa y una barra con una parada numerada antes
/// del punto de recogida. Datos: `minutos`, `vehiculo`, `placa` y `progreso`.
///
/// La parada es el marcador «1» de la barra (la posición se fija con
/// `stopAt`); el auto avanza hacia ella y luego hacia el final.
final class RideStopPreset extends LivePreset {
  const RideStopPreset({
    this.accent = const Color(0xFFE6E6EA),
    this.brand = 'Run',
    this.stopAt = .82,
    this.carImage,
    this.trackerImage,
    this.compactIcon,
    this.chip,
  });

  /// Color de lo recorrido y de la parada.
  final Color accent;

  /// Nombre de la app, arriba a la izquierda.
  final String brand;

  /// Posición de la parada en la barra (0 a 1).
  final double stopAt;

  /// Imagen del auto, sin fondo. Por defecto es un sedán con su placa ya
  /// dibujada; con una imagen propia la placa sale del campo `placa`.
  final LiveImage? carImage;

  /// Auto que avanza sobre la barra (vista desde arriba, sin fondo).
  final LiveImage? trackerImage;

  /// Ícono o imagen de la isla compacta y la mínima (por defecto un auto).
  final LiveVisual? compactIcon;

  /// Chip de Android; por defecto «En ruta».
  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'ride_stop',
    appName: brand,
    accent: accent,
    icon: presetIcon('car.fill', 'car'),
    countdown: false,
    progress: PresetProgress.bar,
    buttons: const [],
    chip: chip ?? const LiveChip.text('En ruta'),
    sample: const PresetSample(
      title: 'Quedan 20 min',
      subtitle: 'Sedán negro',
      name: 'Run',
      highlight: '20 min',
      progress: .18,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'minutos': '20 min',
    'vehiculo': 'Sedán negro',
    'placa': 'PXR784',
    'progreso': .18,
  };

  LiveVisual get _compact =>
      compactIcon ?? presetIcon('car.fill', 'car', accent: true);

  /// Con la imagen por defecto la placa ya viene dibujada; con una imagen
  /// propia se dibuja la placa del estado (`placa`) encima del auto.
  LiveNode _carWithPlate(double height) =>
      carImage == null
          ? LiveImage.asset(
            liveDesignCarPlateAsset,
            width: 560,
            height: 258,
            shape: LiveShape.square,
          ).withHeight(height)
          : LiveColumn(
            [_plate('placa'), carImage!.withHeight(height * .6)],
            gap: 2,
            align: LiveAlign.end,
          );

  LiveNode get _bar => LiveProgress.bar(
    value: const LiveBind('progreso'),
    tracker: _tracker(trackerImage),
    style: LiveProgressStyle(
      height: 5,
      color: accent,
      trackColor: const Color(0xFF3A3A3F),
      // La parada numerada y, al final, el punto de recogida.
      markers: [stopAt],
      markerLabels: const ['1'],
      pointShape: LivePointShape.circle,
      pointColor: accent,
      endMarker: LivePointShape.target,
      pointSize: 22,
    ),
  );

  LiveNode get _brand =>
      LiveText.literal(brand, size: 22, weight: 800, color: _white);

  LiveNode get _titles => LiveColumn([
    LiveText.format(
      'Quedan {minutos}',
      size: 22,
      weight: 700,
      color: _white,
      lines: 1,
    ),
    _field('vehiculo', size: 15, color: _soft, lines: 1),
  ], gap: 2);

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent),
    appLogo: presetIcon('car.fill', 'car'),
    compactLeading: _compact,
    compactTrailing: _field('minutos', size: 14, weight: 700, color: _white),
    minimal: _compact,
    // La marca y la placa junto al sensor; el resto abajo, a todo el ancho.
    expanded: LiveExpanded(
      leading: LivePadding(_brand, horizontal: 6),
      // El auto con su placa va a la derecha del título, no pegado al sensor.
      bottom: LiveColumn([
        LiveRow([_titles, const LiveSpacer(), _carWithPlate(46)]),
        _bar,
      ], gap: 8),
    ),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: const Color(0xFF000000),
        radius: 22,
        child: LivePadding(
          LiveColumn([
            LiveRow([_brand, const LiveSpacer()]),
            LiveRow([_titles, const LiveSpacer(), _carWithPlate(52)]),
            _bar,
          ], gap: 8),
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    android: LiveAndroid(
      title: const LiveText.format('Quedan {minutos}'),
      text: const LiveText.format('{vehiculo} · {placa}'),
      chip: chip ?? const LiveChip.text('En ruta'),
    ),
  );
}

/// Rumbo al destino: la hora de llegada, hacia dónde va y una barra que termina
/// en un cuadrado pegado. Datos: `hora`, `direccion` y `progreso`.
///
/// Es la fase que sigue a la entrega del PIN, y la versión más simple de un
/// viaje con barra.
final class RideDestinationPreset extends LivePreset {
  const RideDestinationPreset({
    this.accent = const Color(0xFFFFFFFF),
    this.brand = 'Run',
    this.trackerImage,
    this.compactIcon,
    this.chip,
  });

  /// Color de lo recorrido.
  final Color accent;

  /// Nombre de la app, arriba a la izquierda.
  final String brand;

  /// Auto que avanza sobre la barra (vista desde arriba, sin fondo).
  final LiveImage? trackerImage;

  /// Ícono o imagen de la isla compacta y la mínima (por defecto un auto).
  final LiveVisual? compactIcon;

  /// Chip de Android; por defecto «Destino».
  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'ride_destination',
    appName: brand,
    accent: accent,
    icon: presetIcon('car.fill', 'car'),
    countdown: false,
    progress: PresetProgress.bar,
    buttons: const [],
    chip: chip ?? const LiveChip.text('Destino'),
    sample: const PresetSample(
      title: 'Destino 8:37 PM',
      subtitle: 'En camino a Av. Los Cedros 234',
      name: 'Run',
      highlight: '8:37 PM',
      progress: .1,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'hora': '8:37 PM',
    'direccion': 'Av. Los Cedros 234',
    'progreso': .1,
  };

  LiveVisual get _compact =>
      compactIcon ?? presetIcon('car.fill', 'car', accent: true);

  LiveNode get _bar => LiveProgress.bar(
    value: const LiveBind('progreso'),
    tracker: _tracker(trackerImage),
    style: LiveProgressStyle(
      height: 5,
      color: accent,
      trackColor: const Color(0xFF4A4A50),
      endMarker: LivePointShape.targetSquare,
      pointSize: 18,
      pointColor: const Color(0xFF8A8D94),
    ),
  );

  LiveNode get _brand =>
      LiveText.literal(brand, size: 22, weight: 800, color: _white);

  LiveNode _titles(double size) => LiveColumn([
    LiveText.format(
      'Destino {hora}',
      size: size,
      weight: 700,
      color: _white,
      lines: 1,
    ),
    LiveText.format(
      'En camino a {direccion}',
      size: size * .62,
      color: _soft,
      lines: 1,
    ),
  ], gap: 3);

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent),
    appLogo: presetIcon('car.fill', 'car'),
    compactLeading: _compact,
    compactTrailing: _field('hora', size: 14, weight: 700, color: _white),
    minimal: _compact,
    // La marca junto al sensor; el destino y la barra abajo, a todo el ancho.
    expanded: LiveExpanded(
      leading: LivePadding(_brand, horizontal: 6),
      bottom: LiveColumn([_titles(20), _bar], gap: 10),
    ),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: const Color(0xFF000000),
        radius: 22,
        child: LivePadding(
          LiveColumn([_brand, _titles(24), _bar], gap: 10),
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    android: LiveAndroid(
      title: const LiveText.format('Destino {hora}'),
      text: const LiveText.format('En camino a {direccion}'),
      chip: chip ?? const LiveChip.text('Destino'),
    ),
  );
}
