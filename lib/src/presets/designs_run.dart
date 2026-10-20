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

/// Plate inside a bordered box.
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

/// Car that moves along the bar, seen from above.
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

/// Arrival: what time you will arrive and how much you pay, with no bar. Data: `hora`,
/// `pago`, `placa`.
///
/// It is the simplest version of a trip in progress: brand and car with its plate
/// at the top, the arrival time on the left and the fare on the right.
final class RideArrivalPreset extends LivePreset {
  const RideArrivalPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFF6FA8FF),
    this.background = const Color(0xFF000000),
    this.brand = 'Run',
    this.carImage,
    this.compactIcon,
    this.chip,
  });

  /// Color of the amount.
  final Color accent;

  /// Background of the whole lock screen card (black). The design's color is in
  /// the text: [accent].
  final Color background;

  /// Name of the app, at the top left of the card.
  final String brand;

  /// Image of the car, no background. By default it is a sedan with its plate
  /// already drawn; with your own image the plate comes from the `placa` field.
  final LiveImage? carImage;

  /// Icon or image of the compact and minimal island (a car by default).
  final LiveVisual? compactIcon;

  /// Android chip; by default the amount.
  final LiveChip? chip;

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

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

  /// With the default image the plate is already drawn; with your own image
  /// the state's plate (`placa`) is drawn below the car.
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

  /// Arrival time on the left and fare on the right.
  LiveNode get _arrivalRow => LiveRow([
    LiveColumn([
      LiveText.literal(
        'Llegarás aproximadamente',
        size: 16,
        weight: 600,
        color: _white,
        lines: 1,
      ),
      LiveText.format(
        'a las {hora}',
        size: 16,
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
      style: androidStyle,
      title: const LiveText.format('Llegarás a las {hora}'),
      text: const LiveText.format('Pago {pago} · {placa}'),
      chip: chip ?? const LiveChip.text('S/14'),
    ),
  );
}

/// Trip in progress with details: phase, destination, address, category and fare, with
/// a bar that ends in a square. Data: `fase`, `hora`, `direccion`,
/// `categoria`, `pago`, `progreso`.
///
/// `fase` changes with what the server sends ("EN CAMINO AL DESTINO",
/// "EL CONDUCTOR LLEGÓ"…) without changing the design.
final class RideTripPreset extends LivePreset {
  const RideTripPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFFB794FF),
    this.background = const Color(0xFF000000),
    this.brand = 'Run',
    this.driverInitials = 'A',
    this.driverPhoto,
    this.trackerImage,
    this.compactIcon,
    this.chip,
  });

  /// Color of the phase, the amount and the completed part.
  final Color accent;

  /// Background of the whole lock screen card (black). The design's color is in
  /// the text and the bar: [accent].
  final Color background;

  /// Name of the app.
  final String brand;

  /// Driver's initials (if there is no [driverPhoto]).
  final String driverInitials;

  /// Circular photo of the driver.
  final LiveImage? driverPhoto;

  /// Car that moves along the bar (seen from above, no background).
  final LiveImage? trackerImage;

  /// Icon or image of the compact and minimal island (a car by default).
  final LiveVisual? compactIcon;

  /// Android chip; by default "En ruta" ("On the way").
  final LiveChip? chip;

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

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

  /// Destination with address on the left, category with fare on the right and
  /// the bar below. The address is what gets cut with "…", never the fare.
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
      style: androidStyle,
      title: const LiveText.format('Destino {hora}'),
      text: const LiveText.format('{direccion}'),
      chip: chip ?? const LiveChip.text('En ruta'),
    ),
  );
}

/// Tracking of a delivery order in four stages: the store receives it,
/// prepares it, the courier picks it up and it reaches the customer. Data: `titulo`,
/// `hora` and `progreso` (0 to 1: 0 received, 1/3 preparing, 2/3 on the way, 1
/// delivered).
///
/// Each stage has its icon in gray until it is reached and colored once it is;
/// the segments between icons are painted the same. The title changes with what
/// the server sends ("Pedido recibido", "Preparando tu pedido"…).
final class DeliveryOrderPreset extends LivePreset {
  const DeliveryOrderPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFFFF8A1F),
    this.brand = 'Run',
    this.compactIcon,
    this.chip,
  });

  /// Color of the segments already completed and of the time.
  final Color accent;

  /// Name of the app, at the top left.
  final String brand;

  /// Icon of the compact and minimal island (the delivery backpack by default).
  final LiveVisual? compactIcon;

  /// Android chip; by default "Pedido" ("Order").
  final LiveChip? chip;

  static const _stages = ['Recibido', 'Preparando', 'En camino', 'Entregado'];
  static const _gray = Color(0xFF4A4A50);

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

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
      style: androidStyle,
      title: const LiveText.format('{titulo}'),
      text: const LiveText.format('{hora} Llegada estimada'),
      chip: chip ?? const LiveChip.text('Pedido'),
    ),
  );
}

/// Start of a trip with the PIN code you tell the driver: brand and
/// four boxes with the PIN, how long is left, who to wait for and their photo, with the
/// car's bar toward the pickup point. Data: `minutos`, `conductor`,
/// `pin1`, `pin2`, `pin3`, `pin4` and `progreso`.
///
/// The PIN goes digit by digit (`pin1` to `pin4`) to draw one box for each
/// one; it shows on the island and on the lock screen even if the app is closed.
final class RidePinPreset extends LivePreset {
  const RidePinPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFF3B6CFF),
    this.brand = 'Run',
    this.driverInitials = 'M',
    this.driverPhoto,
    this.trackerImage,
    this.compactIcon,
    this.chip,
  });

  /// Color of the PIN boxes.
  final Color accent;

  /// Name of the app, at the top left.
  final String brand;

  /// Driver's initials (if there is no [driverPhoto]).
  final String driverInitials;

  /// Circular photo of the driver.
  final LiveImage? driverPhoto;

  /// Car that moves along the bar (seen from above, no background).
  final LiveImage? trackerImage;

  /// Icon or image of the compact and minimal island (a car by default).
  final LiveVisual? compactIcon;

  /// Android chip; by default "PIN".
  final LiveChip? chip;

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

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

  /// One box per PIN digit.
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

  /// "Inicio de viaje en 1 min" ("Trip starts in 1 min") and, below, who to wait for.
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
      style: androidStyle,
      title: const LiveText.format('Inicio de viaje en {minutos}'),
      text: const LiveText.format('Tu PIN: {pin1}{pin2}{pin3}{pin4}'),
      chip: chip ?? const LiveChip.text('PIN'),
    ),
  );
}

/// The driver still has to drop off another passenger before coming for you:
/// how long is left, the car with its plate and a bar with a numbered stop before
/// the pickup point. Data: `minutos`, `vehiculo`, `placa` and `progreso`.
///
/// The stop is the "1" marker on the bar (its position is set with
/// `stopAt`); the car moves toward it and then toward the end.
final class RideStopPreset extends LivePreset {
  const RideStopPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFFE6E6EA),
    this.brand = 'Run',
    this.stopAt = .82,
    this.carImage,
    this.trackerImage,
    this.compactIcon,
    this.chip,
  });

  /// Color of the completed part and of the stop.
  final Color accent;

  /// Name of the app, at the top left.
  final String brand;

  /// Position of the stop on the bar (0 to 1).
  final double stopAt;

  /// Image of the car, no background. By default it is a sedan with its plate
  /// already drawn; with your own image the plate comes from the `placa` field.
  final LiveImage? carImage;

  /// Car that moves along the bar (seen from above, no background).
  final LiveImage? trackerImage;

  /// Icon or image of the compact and minimal island (a car by default).
  final LiveVisual? compactIcon;

  /// Android chip; by default "En ruta" ("On the way").
  final LiveChip? chip;

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

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

  /// With the default image the plate is already drawn; with your own image
  /// the state's plate (`placa`) is drawn above the car.
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
      style: androidStyle,
      title: const LiveText.format('Quedan {minutos}'),
      text: const LiveText.format('{vehiculo} · {placa}'),
      chip: chip ?? const LiveChip.text('En ruta'),
    ),
  );
}

/// On the way to the destination: the arrival time, where it is going and a bar that ends
/// in an attached square. Data: `hora`, `direccion` and `progreso`.
///
/// It is the phase that follows the delivery of the PIN, and the simplest version of a
/// trip with a bar.
final class RideDestinationPreset extends LivePreset {
  const RideDestinationPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFFFFFFFF),
    this.brand = 'Run',
    this.trackerImage,
    this.compactIcon,
    this.chip,
  });

  /// Color of the completed part.
  final Color accent;

  /// Name of the app, at the top left.
  final String brand;

  /// Car that moves along the bar (seen from above, no background).
  final LiveImage? trackerImage;

  /// Icon or image of the compact and minimal island (a car by default).
  final LiveVisual? compactIcon;

  /// Android chip; by default "Destino" ("Destination").
  final LiveChip? chip;

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

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
      style: androidStyle,
      title: const LiveText.format('Destino {hora}'),
      text: const LiveText.format('En camino a {direccion}'),
      chip: chip ?? const LiveChip.text('Destino'),
    ),
  );
}

/// Train line: how many stops are left, where it is going and a bar by
/// stations with the train on top. Data: `titulo`, `subtitulo`, `destacado`,
/// `nombre` and `progreso`.
///
/// The key value (`destacado`, "3 paradas") goes to the right of the title and
/// is never cut; the long part (the stop's name) goes in Android's text
/// and does not compete for the island's width.
final class TrainPreset extends LivePreset {
  const TrainPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFFA7F060),
    this.brand = 'Ruta Lima',
    this.stages = const ['El Ángel', 'Miguel Grau', 'Gamarra'],
    this.trainImage,
    this.compactIcon,
    this.chip,
  });

  /// Color of the completed part and of the key value.
  final Color accent;

  /// Name of the app.
  final String brand;

  /// Stations of the bar (at least two).
  final List<String> stages;

  /// Train seen from above, no background; by default the package's.
  final LiveImage? trainImage;

  /// Icon or image of the compact and minimal island (a bus by default).
  final LiveVisual? compactIcon;

  /// Android chip; by default "3 par.".
  final LiveChip? chip;

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'train_line',
    appName: brand,
    accent: accent,
    icon: presetIcon('bus.fill', 'bus'),
    countdown: false,
    progress: PresetProgress.segments,
    stages: stages,
    buttons: const [],
    chip: chip ?? const LiveChip.text('3 par.'),
    sample: const PresetSample(
      title: 'Bájate en 3 paradas',
      subtitle: 'Línea 201 · Javier Prado',
      name: 'Paradero Las Begonias',
      highlight: '3 paradas',
      progress: .55,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'titulo': 'Bájate en 3 paradas',
    'subtitulo': 'Línea 201 · Javier Prado',
    'nombre': 'Paradero Las Begonias',
    'destacado': '3 paradas',
    'progreso': .55,
  };

  LiveVisual get _compact =>
      compactIcon ?? presetIcon('bus.fill', 'bus', accent: true);

  LiveNode get _bar => LiveSegments(
    value: const LiveBind('progreso'),
    labels: stages,
    points: true,
    tracker: LiveTracker(
      trainImage ??
          LiveImage.asset(
            liveDesignTrainTopAsset,
            width: 360,
            height: 70,
            shape: LiveShape.square,
          ),
      height: 22,
      background: LiveTrackerBackground.none,
    ),
    style: LiveProgressStyle(
      height: 14,
      color: accent,
      trackColor: const Color(0xFF2F6A12),
      pointSize: 12,
      pointColor: const Color(0xFF000000),
      gap: 0,
    ),
  );

  LiveNode _body(double titleSize) => LiveColumn([
    LiveRow([
      LiveColumn([
        LiveText(
          const LiveBind('titulo'),
          size: titleSize,
          weight: 700,
          color: _white,
          lines: 1,
        ),
        _field('subtitulo', size: 13, color: _soft, lines: 1),
      ], gap: 2),
      const LiveSpacer(size: 8),
      const LiveSpacer(),
      _field(
        'destacado',
        size: titleSize - 2,
        weight: 800,
        color: accent,
        lines: 1,
      ),
    ]),
    _bar,
  ], gap: 10);

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent),
    appLogo: presetIcon('bus.fill', 'bus'),
    compactLeading: _compact,
    compactTrailing: _field('destacado', size: 14, weight: 700, color: accent),
    minimal: _compact,
    // Todo en una pieza a todo el ancho: nada compite con el dato clave.
    expanded: LiveExpanded(bottom: _body(18)),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: const Color(0xFF000000),
        radius: 22,
        child: LivePadding(
          LiveColumn([
            LiveText.literal(brand, size: 20, weight: 800, color: _white),
            _body(18),
          ], gap: 10),
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    android: LiveAndroid(
      style: androidStyle,
      title: const LiveBind('titulo'),
      text: const LiveText.format('{subtitulo} · {nombre}'),
      chip: chip ?? const LiveChip.text('3 par.'),
    ),
  );
}
