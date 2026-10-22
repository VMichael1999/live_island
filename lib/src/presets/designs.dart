// Diseños de referencia: tarjetas más elaboradas que los 15 presets de la
// galería, pensadas como punto de partida para que cada app haga el suyo.
//
// Cada uno es un `LivePreset` normal (`.build()`, `.override(...)`,
// `.sampleState()`), con la isla negra y una tarjeta de bloqueo propia. Las
// imágenes son dibujos genéricos que trae el paquete: sustitúyelos por los
// tuyos con `LiveImage.asset(...)`.
import 'dart:ui' show Color;

import '../components/actions.dart';
import '../components/charts.dart';
import '../components/layout_nodes.dart';
import '../components/progress.dart';
import '../components/text.dart';
import '../components/visuals.dart';
import '../core/bind.dart';
import '../core/enums.dart';
import '../core/layout.dart';
import '../core/node.dart';
import 'preset.dart';
import 'presets.dart' show livePresetCarAsset;

/// A car seen from above, to move along a bar.
const liveDesignCarTopAsset = livePresetCarAsset;

/// A car seen from the side, to accompany the driver.
const liveDesignCarSideAsset =
    'packages/live_island_kit/assets/presets/car_side.png';

/// A sedan seen from the front with its plate (CSB488) drawn, no background.
const liveDesignCarPlateAsset =
    'packages/live_island_kit/assets/presets/car_plate.png';

/// Icon of a delivery order stage (1 notepad, 2 pot, 3 delivery backpack,
/// 4 bag with a location), gray until the stage is reached and colored
/// afterwards.
String liveDesignOrderAsset(int stage, {required bool reached}) =>
    'packages/live_island_kit/assets/presets/'
    'pedido_${stage}_${reached ? 'color' : 'gris'}.png';

/// A train seen from above, to move along a bar (no background).
const liveDesignTrainTopAsset =
    'packages/live_island_kit/assets/presets/train_top.png';

/// Generic blue and red crest (sample home team).
const liveDesignCrestAAsset =
    'packages/live_island_kit/assets/presets/crest_a.png';

/// Generic yellow and navy crest (sample away team).
const liveDesignCrestBAsset =
    'packages/live_island_kit/assets/presets/crest_b.png';

const _ink = Color(0xFF0B0B0D);
const _white = Color(0xFFFFFFFF);

LiveNode _t(
  String field, {
  double? size,
  int? weight,
  Color? color,
  bool muted = false,
  bool accent = false,
  int? lines,
  LiveAlign? align,
}) => LiveText(
  LiveBind(field),
  size: size,
  weight: weight,
  color: color,
  muted: muted,
  accent: accent,
  lines: lines,
  align: align,
);

/// How the pickup bar is drawn.
enum RideBar {
  /// Continuous line from departure to destination, with a marker at the end.
  line,

  /// Dashed stroke with intermediate markers.
  dotted,
}

/// Ride pickup: time, driver with their car, plate and a bar with the car
/// moving toward the pickup point.
///
/// The light card uses the [RideBar.dotted] bar (dotted, with markers) and
/// the dark one [RideBar.line] (continuous, with an end marker); [bar] changes
/// either. Data: `tiempo`, `titulo`, `subtitulo`, `placa`, `vehiculo`,
/// `nombre`, `progreso`. On the dark one the title goes before the time
/// ("Pickup in 2 min"); on the light one, after ("2 min until pickup").
final class RidePickupPreset extends LivePreset {
  const RidePickupPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.dark = false,
    this.accent = const Color(0xFF1F5EFF),
    this.brand = 'Run',
    this.driverInitials = 'A',
    this.driverPhoto,
    this.carImage,
    this.brandLogo,
    this.headerImage,
    this.trackerImage,
    this.compactIcon,
    this.bar,
    this.showCar = true,
    this.buttons,
    this.chip,
  });

  /// Dark card instead of light.
  final bool dark;

  /// Color of the time and of the completed part on the light card; of the island.
  final Color accent;

  /// Name of the app, at the top left of the card.
  final String brand;

  /// Driver's initials (if there is no [driverPhoto]).
  final String driverInitials;

  /// Circular photo of the driver.
  final LiveImage? driverPhoto;

  /// Image of the car next to the driver; by default the one the package ships.
  final LiveImage? carImage;

  /// Logo instead of the app name, at the top left.
  final LiveImage? brandLogo;

  /// A single image with the driver and their car, no background (replaces
  /// [driverPhoto] and [carImage] on the lock screen card).
  final LiveImage? headerImage;

  /// Image of the car that moves along the bar (seen from above, no background).
  final LiveImage? trackerImage;

  /// Icon or image of the compact and minimal island (a car by default).
  final LiveVisual? compactIcon;

  /// Style of the bar; by default dotted on the light card and continuous on the dark one.
  final RideBar? bar;

  /// Shows the driver and their car at the top right.
  final bool showCar;

  /// Buttons of the lock screen card and of Android.
  final List<LiveButton>? buttons;

  /// Android chip; by default the time.
  final LiveChip? chip;

  RideBar get _bar => bar ?? (dark ? RideBar.line : RideBar.dotted);

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: dark ? 'ride_pickup_dark' : 'ride_pickup',
    appName: brand,
    accent: accent,
    icon: presetIcon('car.fill', 'car'),
    countdown: false,
    progress: PresetProgress.bar,
    buttons: buttons ?? const [],
    chip: chip ?? const LiveChip.text('2 min'),
    sample: const PresetSample(
      title: 'until pickup',
      subtitle: 'Andrés arrives shortly',
      name: 'Andrés',
      highlight: '2 min',
      progress: 0.34,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'tiempo': '2 min',
    'titulo': dark ? 'Pickup in' : 'until pickup',
    'subtitulo': 'Andrés arrives shortly',
    'placa': 'A1B-234',
    'vehiculo': 'Silver sedan',
    'nombre': 'Andrés',
    'progreso': 0.34,
  };

  // Iniciales sobre un círculo del color de acento (no del tema: en la tarjeta
  // oscura el tema es casi negro).
  LiveNode get _driver => _driverAvatar(34);

  LiveNode _driverAvatar(double size) =>
      driverPhoto != null
          ? LiveAvatar.photo(driverPhoto!, size: size)
          : LiveBox(
            size: size,
            radius: size / 2,
            color: accent,
            child: LiveText.literal(
              driverInitials,
              size: size * .44,
              weight: 700,
              color: _white,
            ),
          );

  LiveImage get _car =>
      carImage ??
      LiveImage.asset(
        liveDesignCarSideAsset,
        width: 110,
        height: 46,
        shape: LiveShape.square,
        size: 74,
      );

  LiveVisual get _compact =>
      compactIcon ??
      LiveIcon.symbol(
        'car.fill',
        android: presetIcon('car.fill', 'car').android,
        color: accent,
      );

  LiveNode _progress(Color fill, Color track) {
    final tracker = LiveTracker(
      trackerImage ??
          LiveImage.asset(
            liveDesignCarTopAsset,
            width: 212,
            height: 113,
            shape: LiveShape.square,
          ),
      height: 24,
      background: LiveTrackerBackground.none,
    );
    if (_bar == RideBar.line) {
      return LiveProgress.bar(
        value: const LiveBind('progreso'),
        tracker: tracker,
        // Marcador pegado a la barra; el auto lo cubre al llegar.
        style: LiveProgressStyle(
          height: 4,
          color: fill,
          trackColor: track,
          endMarker: LivePointShape.target,
          pointSize: 16,
          pointColor: const Color(0xFFD9DADF),
        ),
      );
    }
    return LiveProgress.bar(
      value: const LiveBind('progreso'),
      tracker: tracker,
      style: LiveProgressStyle(
        height: 4,
        color: fill,
        trackColor: track,
        dashed: true,
        pointShape: LivePointShape.ring,
        pointSize: 18,
        markers: const [.62, 1],
      ),
    );
  }

  @override
  LiveLayout build() {
    final ink = dark ? _white : _ink;
    final fill = dark ? _white : accent;
    final track = dark ? const Color(0xFF6B6E75) : const Color(0xFFB4B4B9);
    final subtle = dark ? const Color(0xFFB4B6BC) : _ink;

    LiveNode header() => LiveRow([
      brandLogo ?? LiveText.literal(brand, size: 22, weight: 800, color: ink),
      const LiveSpacer(),
      if (showCar && headerImage != null)
        headerImage!
      else if (showCar)
        LiveRow([_driver, _car], gap: 0),
    ]);

    // Oscura: «Recogida en 2 min» y, debajo, «placa • vehículo».
    final darkBody = LiveColumn([
      LiveRow([
        _t('titulo', size: 24, weight: 700, color: ink),
        _t('tiempo', size: 24, weight: 700, color: ink),
      ], gap: 6),
      LiveText.format('{placa} • {vehiculo}', size: 15, color: subtle),
    ], gap: 3);

    // Clara: «2 min para la recogida» a todo el ancho y, debajo, el subtítulo con
    // la placa a la derecha (así el título no compite por el ancho).
    final lightBody = LiveColumn([
      LiveRow([
        _t('tiempo', size: 21, weight: 700, color: accent),
        _t('titulo', size: 21, weight: 700, color: ink, lines: 1),
      ], gap: 6),
      LiveRow([
        _t('subtitulo', size: 15, color: subtle, lines: 1),
        const LiveSpacer(),
        _t('placa', size: 16, weight: 700, color: ink),
      ]),
    ], gap: 3);

    final card = LiveColumn([
      header(),
      dark ? darkBody : lightBody,
      _progress(fill, track),
      if ((buttons ?? const []).isNotEmpty) LiveRow(buttons!),
    ], gap: 6);

    return LiveLayout(
      // La tarjeta oscura es de color sólido (acento oscuro): se ve igual con
      // el sistema en claro o en oscuro. Los colores de la isla son explícitos.
      theme: LiveTheme(
        accent: dark ? const Color(0xFF16181C) : accent,
        background: dark ? LiveBackground.accent : LiveBackground.light,
      ),
      appLogo: presetIcon('car.fill', 'car'),
      compactLeading: _compact,
      compactTrailing: _t('tiempo', size: 15, weight: 700, color: _white),
      minimal: _compact,
      // Todo en una sola pieza a todo el ancho: en la isla real iOS reparte las
      // zonas laterales y el avatar quedaba suelto en la esquina.
      expanded: LiveExpanded(
        bottom: LiveColumn([
          LiveRow([
            _driverAvatar(44),
            LiveColumn([
              LiveRow(
                dark
                    ? [
                      _t(
                        'titulo',
                        size: 19,
                        weight: 700,
                        color: _white,
                        lines: 1,
                      ),
                      _t('tiempo', size: 19, weight: 700, color: _white),
                    ]
                    : [
                      _t('tiempo', size: 19, weight: 700, color: accent),
                      _t(
                        'titulo',
                        size: 19,
                        weight: 700,
                        color: _white,
                        lines: 1,
                      ),
                    ],
                gap: 5,
              ),
              LiveText.format(
                '{placa} · {vehiculo}',
                size: 14,
                color: const Color(0xFFB4B6BC),
                lines: 1,
              ),
            ], gap: 2),
          ], gap: 10),
          _progress(_white, const Color(0xFF6B6E75)),
        ], gap: 10),
      ),
      lockScreen: LiveLockScreen.custom(card),
      // Android añade el tiempo al título («Recogida · 2 min»).
      android: LiveAndroid(
        style: androidStyle,
        title: const LiveText.literal('Pickup'),
        text: const LiveText.format('{subtitulo} · {placa}'),
        subText: const LiveBind('vehiculo'),
        largeIcon: driverPhoto,
        // En Android la barra va del color de acento (el fondo lo decide el sistema).
        progress: _progress(accent, const Color(0xFFB4B4B9)),
        chip: chip ?? const LiveChip.text('2 min'),
      ),
    );
  }
}

/// Store pickup order: three steps with icons (received, preparing,
/// ready) where the current step grows and turns white.
///
/// Data: `titulo`, `subtitulo`, `corto` (one word for the compact island),
/// `etapa` (0, 1 or 2), `progreso`.
final class StorePickupPreset extends LivePreset {
  const StorePickupPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFF1E3932),
    this.stepColor = const Color(0xFF00A862),
    this.store = 'Store pickup',
    this.brandLogo,
    this.people,
    this.buttons,
    this.chip,
  });

  /// Background of the card.
  final Color accent;

  /// Color of the steps that are not the current one.
  final Color stepColor;

  /// Header of the card.
  final String store;

  /// Logo next to the header (an icon by default).
  final LiveImage? brandLogo;

  /// People who receive the order (initials); two by default.
  final List<String>? people;

  final List<LiveButton>? buttons;
  final LiveChip? chip;

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'store_pickup',
    appName: store,
    accent: accent,
    icon: presetIcon('cup.and.saucer.fill', 'coffee'),
    countdown: false,
    progress: PresetProgress.none,
    buttons: buttons ?? const [],
    chip: chip ?? const LiveChip.text('Preparing'),
    sample: const PresetSample(
      title: 'Order being prepared',
      subtitle: 'We are carefully preparing your order',
      name: 'Store',
      progress: 0.5,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'titulo': 'Order being prepared',
    'subtitulo': 'We are carefully preparing your order',
    'corto': 'Preparing',
    'nombre': store,
    'etapa': 1,
    'progreso': 0.5,
  };

  LiveNode _step(int i, LiveIcon icon, LiveIcon accentIcon) => LiveIf(
    LiveBind('etapa').equals(i),
    then: LiveBox(child: accentIcon, size: 40, radius: 20, color: _white),
    otherwise: LiveBox(child: icon, size: 26, radius: 13, color: stepColor),
  );

  LiveNode get _rail {
    const steps = [
      ('location.fill', 'mappin'),
      ('person.fill', 'user'),
      ('cup.and.saucer.fill', 'coffee'),
    ];
    return LiveRow([
      for (var i = 0; i < steps.length; i++)
        _step(
          i,
          // Paso pendiente: ícono blanco sobre el color del paso.
          presetIcon(steps[i].$1, steps[i].$2),
          // Paso actual: círculo blanco con el ícono del color de la tarjeta.
          LiveIcon.symbol(
            steps[i].$1,
            android: presetIcon(steps[i].$1, steps[i].$2).android,
            color: accent,
          ),
        ),
    ], gap: 12);
  }

  @override
  LiveLayout build() {
    final steps = _rail;
    final mark = brandLogo ?? presetIcon('cup.and.saucer.fill', 'coffee');
    return LiveLayout(
      theme: LiveTheme(accent: accent, background: LiveBackground.accent),
      appLogo: presetIcon('cup.and.saucer.fill', 'coffee'),
      compactLeading: mark,
      compactTrailing: _t('corto', size: 13, weight: 600, lines: 1),
      minimal: mark,
      // Título y subtítulo ocupan todo el ancho; los pasos van debajo.
      expanded: LiveExpanded(
        center: LiveColumn(
          [
            _t('titulo', size: 18, weight: 700, lines: 1),
            _t('subtitulo', size: 13, muted: true, lines: 2),
          ],
          align: LiveAlign.center,
          gap: 3,
        ),
        bottom: LiveRow([const LiveSpacer(), steps, const LiveSpacer()]),
      ),
      lockScreen: LiveLockScreen.custom(
        LiveColumn([
          LiveRow([
            LiveRow([
              mark,
              LiveText.literal(store, size: 14, color: _white),
            ], gap: 8),
            const LiveSpacer(),
            LiveRow([
              for (final p in people ?? const ['S', 'D'])
                LiveBox(
                  size: 24,
                  radius: 12,
                  color: stepColor,
                  child: LiveText.literal(
                    p,
                    size: 11,
                    weight: 700,
                    color: _white,
                  ),
                ),
            ], gap: 0),
          ]),
          LiveColumn([
            _t('titulo', size: 22, weight: 700, color: _white),
            _t('subtitulo', size: 13, color: const Color(0xFFB7CBC4), lines: 1),
          ], gap: 2),
          LiveRow([steps, const LiveSpacer()]),
          if ((buttons ?? const []).isNotEmpty) LiveRow(buttons!),
        ], gap: 6),
      ),
      // Android añade la palabra corta al título («Tu pedido · Preparando»).
      android: LiveAndroid(
        style: androidStyle,
        title: const LiveText.literal('Your order'),
        text: const LiveBind('subtitulo'),
        subText: LiveText.literal(store),
        largeIcon: brandLogo,
        chip: chip ?? const LiveChip.text('Preparing'),
      ),
    );
  }
}

/// Run or workout: big distance, time and a goal bar.
///
/// Data: `distancia`, `tiempo`, `progreso`.
final class RunPreset extends LivePreset {
  const RunPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFF45C8FF),
    this.unit = 'Kilometers',
    this.timeLabel = 'Time',
    this.brand = 'Sprint',
    this.buttons,
    this.chip,
  });

  /// Color of the card.
  final Color accent;

  /// Unit under the distance.
  final String unit;

  /// Label under the time.
  final String timeLabel;

  /// Name of the app, at the top right of the card.
  final String brand;

  final List<LiveButton>? buttons;
  final LiveChip? chip;

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'run',
    appName: 'Run',
    accent: accent,
    icon: presetIcon('figure.run', 'flag'),
    countdown: false,
    progress: PresetProgress.bar,
    buttons: buttons ?? const [],
    chip: chip ?? const LiveChip.text('4,72'),
    sample: const PresetSample(
      title: '4,72',
      subtitle: 'Kilometers',
      name: 'Time',
      highlight: '25:38',
      progress: 0.78,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'distancia': '4,72',
    'tiempo': '25:38',
    'progreso': 0.78,
  };

  LiveNode _bar(Color fill, Color track) => LiveProgress.bar(
    value: const LiveBind('progreso'),
    style: LiveProgressStyle(height: 6, color: fill, trackColor: track),
  );

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent, background: LiveBackground.accent),
    appLogo: presetIcon('figure.run', 'flag'),
    compactLeading: presetIcon('figure.run', 'flag', accent: true),
    compactTrailing: _t('distancia', size: 15, weight: 700, accent: true),
    minimal: presetIcon('figure.run', 'flag', accent: true),
    expanded: LiveExpanded(
      leading: presetIcon('figure.run', 'flag', accent: true),
      center: LiveColumn([
        _t('distancia', size: 34, weight: 800, accent: true),
        LiveText.literal(unit, size: 12, muted: true),
      ], gap: 0),
      trailing: LiveColumn(
        [
          _t('tiempo', size: 24, weight: 500),
          LiveText.literal(timeLabel, size: 12, muted: true),
        ],
        align: LiveAlign.end,
        gap: 0,
      ),
      bottom: _bar(accent, const Color(0x33FFFFFF)),
    ),
    lockScreen: LiveLockScreen.custom(
      LiveColumn([
        LiveRow([
          LiveColumn([
            _t('distancia', size: 52, weight: 800, color: _ink),
            LiveText.literal(unit, size: 13, color: _ink),
          ], gap: 0),
          const LiveSpacer(),
          LiveColumn(
            [
              LiveText.literal(brand, size: 16, weight: 800, color: _ink),
              _t('tiempo', size: 30, weight: 500, color: _ink),
              LiveText.literal(timeLabel, size: 13, color: _ink),
            ],
            align: LiveAlign.end,
            gap: 0,
          ),
        ], align: LiveAlign.end),
        _bar(_ink, const Color(0x26000000)),
        if ((buttons ?? const []).isNotEmpty) LiveRow(buttons!),
      ], gap: 8),
    ),
    // Android añade la distancia al título («Carrera · 4,72»).
    android: LiveAndroid(
      style: androidStyle,
      title: const LiveText.literal('Run'),
      text: LiveText.format('{distancia} $unit · {tiempo}'),
      chip: chip ?? const LiveChip.text('4,72'),
    ),
  );
}

/// Score of a match: crests, goals in a box, minute and tournament.
///
/// Data: `local`, `visitante`, `golesLocal`, `golesVisitante`, `minuto`,
/// `torneo`, `progreso`.
final class MatchPreset extends LivePreset {
  const MatchPreset({
    this.accent = const Color(0xFF1B5E20),
    this.homeCrest,
    this.awayCrest,
    this.homeLabel = 'Local',
    this.awayLabel = 'Visitante',
    this.link = 'View stats',
    this.androidStyle = LiveAndroidStyle.card,
    this.chip,
  });

  final Color accent;

  /// Crest of the home team (your own image).
  final LiveImage? homeCrest;

  /// Crest of the away team.
  final LiveImage? awayCrest;

  /// Label under the home team's name.
  final String homeLabel;

  /// Label under the away team's name.
  final String awayLabel;

  /// Text of the link under the minute.
  final String link;

  /// On Android: `card` draws the card with the two crests and the score
  /// (no chip or Live Update); `liveUpdate` uses the native style with the
  /// home crest and the chip.
  final LiveAndroidStyle androidStyle;

  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'match',
    appName: 'Match',
    accent: accent,
    icon: presetIcon('trophy.fill', 'trophy'),
    countdown: false,
    progress: PresetProgress.none,
    androidPromotable: false,
    chip: chip ?? const LiveChip.text('3–1'),
    sample: const PresetSample(
      title: 'Lions 3 – 1 Hawks',
      subtitle: 'World Cup',
      name: 'Match',
      highlight: '6:15',
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'local': 'Lions',
    'visitante': 'Hawks',
    'golesLocal': '3',
    'golesVisitante': '1',
    'minuto': '6:15',
    'torneo': 'World Cup',
    'progreso': 0.07,
  };

  LiveImage get _home =>
      homeCrest ??
      LiveImage.asset(
        liveDesignCrestAAsset,
        width: 240,
        height: 280,
        shape: LiveShape.square,
      );

  LiveImage get _away =>
      awayCrest ??
      LiveImage.asset(
        liveDesignCrestBAsset,
        width: 240,
        height: 280,
        shape: LiveShape.square,
      );

  LiveNode _side(LiveImage? crest, String field, String label, double size) =>
      LiveColumn(
        [
          crest?.withSize(size) ??
              presetIcon('trophy.fill', 'trophy', accent: true),
          _t(field, size: 17, weight: 700, color: _white),
          LiveText.literal(label, size: 13, weight: 700, color: _white),
        ],
        align: LiveAlign.center,
        gap: 2,
      );

  @override
  LiveLayout build() {
    LiveNode score(double size, double radius) => LiveBox(
      radius: radius,
      color: const Color(0xFF202020),
      child: LivePadding(
        LiveRow([
          _t('golesLocal', size: size, weight: 800, color: _white),
          LiveText.literal(':', size: size, weight: 800, color: _white),
          _t('golesVisitante', size: size, weight: 800, color: _white),
        ], gap: 6),
        horizontal: 10,
        vertical: 2,
      ),
    );
    LiveNode centre({required double size, required bool full}) => LiveColumn(
      [
        score(size, 12),
        _t('minuto', size: 15, weight: 600, color: _white),
        if (full) LiveText.literal(link, size: 14, color: _white),
        _t('torneo', size: 13, color: _white),
      ],
      align: LiveAlign.center,
      gap: 3,
    );
    return LiveLayout(
      theme: LiveTheme(accent: accent),
      appLogo: presetIcon('trophy.fill', 'trophy'),
      compactLeading: _home.withSize(24),
      compactTrailing: LiveRow([
        _t('golesLocal', size: 15, weight: 800, color: _white),
        LiveText.literal('–', size: 15, weight: 800, color: _white),
        _t('golesVisitante', size: 15, weight: 800, color: _white),
      ], gap: 2),
      minimal: _home.withSize(22),
      expanded: LiveExpanded(
        leading: _side(_home, 'local', homeLabel, 52),
        center: centre(size: 34, full: false),
        trailing: _side(_away, 'visitante', awayLabel, 52),
      ),
      // Tarjeta negra propia (como la isla), igual con el sistema en claro o en oscuro.
      lockScreen: LiveLockScreen.custom(
        LiveBox(
          color: const Color(0xFF000000),
          radius: 28,
          child: LivePadding(
            LiveRow([
              _side(_home, 'local', homeLabel, 56),
              const LiveSpacer(),
              centre(size: 38, full: true),
              const LiveSpacer(),
              _side(_away, 'visitante', awayLabel, 56),
            ], align: LiveAlign.center),
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
      android: LiveAndroid(
        title: const LiveText.format(
          '{local} {golesLocal} – {golesVisitante} {visitante}',
        ),
        text: const LiveBind('torneo'),
        style: androidStyle,
        subText: const LiveBind('minuto'),
        largeIcon: _home.withSize(44),
        chip: chip ?? const LiveChip.text('3–1'),
      ),
    );
  }
}

const _up = Color(0xFF30D158);

/// Stock quote: symbol, price, change and a line chart.
///
/// Data: `simbolo`, `nombre`, `precio`, `cambio` (text, for example
/// `+1.24%`) and `serie` (the latest prices with [liveSeries]).
final class StockPreset extends LivePreset {
  const StockPreset({
    this.accent = _up,
    this.brandLogo,
    this.androidStyle = LiveAndroidStyle.card,
    this.chip,
  });

  /// Color of the line and of the change (green if up, red if down).
  final Color accent;

  /// Logo of the company.
  final LiveImage? brandLogo;

  /// On Android: `card` draws the card with the line chart (no chip or Live
  /// Update); `liveUpdate` uses the native style with text and a chip.
  final LiveAndroidStyle androidStyle;

  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'stock',
    appName: 'Stocks',
    accent: accent,
    icon: presetIcon('chart.line.uptrend.xyaxis', 'landmark'),
    countdown: false,
    progress: PresetProgress.none,
    androidPromotable: false,
    chip: chip ?? const LiveChip.text('+1.2%'),
    sample: const PresetSample(
      title: 'VOLT 219.40',
      subtitle: 'Volt Inc.',
      name: 'Stocks',
      highlight: '+1.24%',
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'simbolo': 'VOLT',
    'nombre': 'Volt Inc.',
    'precio': '219.40',
    'cambio': '+1.24%',
    'tendencia': '▲',
    'serie': liveSeries([
      212,
      213.5,
      212.8,
      214.9,
      214.1,
      216.3,
      215.2,
      217.8,
      216.9,
      218.5,
      219.4,
    ]),
  };

  LiveNode get _mark =>
      brandLogo ??
      presetIcon('chart.line.uptrend.xyaxis', 'landmark', accent: true);

  LiveNode get _spark =>
      LiveSparkline(series: const LiveBind('serie'), height: 44, color: accent);

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent),
    appLogo: presetIcon('chart.line.uptrend.xyaxis', 'landmark'),
    compactLeading: _mark,
    compactTrailing: _t('precio', size: 14, weight: 700, color: accent),
    minimal: _mark,
    expanded: LiveExpanded(
      leading: LiveColumn([
        _mark,
        _t('simbolo', size: 15, weight: 700, color: _white),
      ], gap: 4),
      center: _t('nombre', size: 13, muted: true),
      trailing: LiveColumn(
        [
          _t('precio', size: 24, weight: 700, color: _white),
          _t('cambio', size: 14, weight: 600, color: accent),
        ],
        align: LiveAlign.end,
        gap: 0,
      ),
      bottom: _spark,
    ),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: _ink,
        radius: 28,
        child: LivePadding(
          LiveColumn([
            LiveRow([
              _mark,
              LiveColumn([
                _t('simbolo', size: 17, weight: 700, color: _white),
                _t('nombre', size: 13, muted: true),
              ], gap: 0),
              const LiveSpacer(),
              LiveColumn(
                [
                  _t('precio', size: 26, weight: 700, color: _white),
                  _t('cambio', size: 14, weight: 600, color: accent),
                ],
                align: LiveAlign.end,
                gap: 0,
              ),
            ]),
            _spark,
          ], gap: 4),
          horizontal: 14,
          vertical: 8,
        ),
      ),
    ),
    android: LiveAndroid(
      title: const LiveText.format('{simbolo}'),
      style: androidStyle,
      text: const LiveText.format('{tendencia} {cambio} · {nombre}'),
      largeIcon: brandLogo,
      chip: chip ?? const LiveChip.text('+1.2%'),
    ),
  );
}

/// Flight with the curved route between two airports and the airplane advancing.
///
/// Data: `vuelo`, `estado`, `origen`, `destino`, `aterriza` and `progreso`.
final class FlightPathPreset extends LivePreset {
  const FlightPathPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFF30D158),
    this.carrier,
    this.chip,
  });

  /// Color of the completed part, the airplane and the status.
  final Color accent;

  /// Logo of the airline.
  final LiveImage? carrier;

  final LiveChip? chip;

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'flightpath',
    appName: 'Flight',
    accent: accent,
    icon: presetIcon('airplane', 'plane'),
    countdown: false,
    progress: PresetProgress.bar,
    chip: chip ?? const LiveChip.text('55 min'),
    sample: const PresetSample(
      title: 'LIM → MAD',
      subtitle: 'Lands in 55 min',
      name: 'RA234',
      highlight: 'On time',
      progress: 0.72,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'vuelo': 'RA 234',
    'estado': 'On time',
    'origen': 'LIM',
    'destino': 'MAD',
    'aterriza': 'Lands in 55 min',
    'progreso': 0.72,
  };

  LiveNode get _route => LiveFlightPath(
    value: const LiveBind('progreso'),
    height: 52,
    curve: .9,
    tracker: presetIcon('airplane', 'plane'),
    style: LiveProgressStyle(
      height: 3,
      color: accent,
      trackColor: const Color(0x4DFFFFFF),
      dashed: true,
      trackerSize: 26,
    ),
  );

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent),
    appLogo: presetIcon('airplane', 'plane'),
    compactLeading: presetIcon('airplane', 'plane', accent: true),
    compactTrailing: _t('destino', size: 14, weight: 700, color: accent),
    minimal: presetIcon('airplane', 'plane', accent: true),
    expanded: LiveExpanded(
      leading: _t('origen', size: 26, weight: 700, color: _white),
      center: _t('aterriza', size: 13, color: accent),
      trailing: _t('destino', size: 26, weight: 700, color: _white),
      bottom: _route,
    ),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: _ink,
        radius: 28,
        child: LivePadding(
          LiveColumn([
            LiveRow([
              _t('origen', size: 30, weight: 700, color: _white),
              const LiveSpacer(),
              if (carrier != null) carrier!,
              _t('vuelo', size: 13, weight: 600, muted: true),
              const LiveSpacer(),
              _t('destino', size: 30, weight: 700, color: _white),
            ]),
            _route,
            LiveRow([
              _t('aterriza', size: 13, color: _white),
              const LiveSpacer(),
              _t('estado', size: 13, weight: 600, color: accent),
            ]),
          ], gap: 2),
          horizontal: 14,
          vertical: 6,
        ),
      ),
    ),
    android: LiveAndroid(
      style: androidStyle,
      title: const LiveText.format('{vuelo}'),
      text: const LiveText.format('{origen} → {destino} · {aterriza}'),
      subText: const LiveBind('estado'),
      largeIcon: carrier,
      chip: chip ?? const LiveChip.text('55 min'),
      progress: LiveFlightPath(
        value: const LiveBind('progreso'),
        tracker: presetIcon('airplane', 'plane'),
        style: LiveProgressStyle(color: accent),
      ),
    ),
  );
}

/// Orbit: an arc with a moving dot (the ISS, a satellite, a parking
/// meter). The arc is a [LiveGauge], so `sweep` changes it.
///
/// Data: `titulo`, `lugar`, `tiempo` and `progreso`.
final class OrbitPreset extends LivePreset {
  const OrbitPreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFF64D2FF),
    this.sweep = 180,
    this.chip,
  });

  final Color accent;

  /// Degrees the arc spans.
  final double sweep;

  final LiveChip? chip;

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'orbit',
    appName: 'Orbit',
    accent: accent,
    icon: presetIcon('globe.europe.africa.fill', 'upload'),
    countdown: false,
    progress: PresetProgress.bar,
    chip: chip ?? const LiveChip.text('ISS'),
    sample: const PresetSample(
      title: 'ISS',
      subtitle: 'Over the Pacific Ocean',
      name: 'Orbit',
      highlight: '27 600 km/h',
      progress: 0.38,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'titulo': 'ISS',
    'lugar': 'Over the Pacific Ocean',
    'tiempo': '27 600 km/h',
    'progreso': 0.38,
  };

  LiveNode _arc(double size) => LiveGauge(
    value: const LiveBind('progreso'),
    size: size,
    sweep: sweep,
    style: LiveProgressStyle(
      height: 4,
      color: accent,
      trackColor: const Color(0x40FFFFFF),
      dashed: true,
    ),
    child: presetIcon('globe.europe.africa.fill', 'upload', accent: true),
  );

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent),
    appLogo: presetIcon('globe.europe.africa.fill', 'upload'),
    compactLeading: presetIcon(
      'globe.europe.africa.fill',
      'upload',
      accent: true,
    ),
    compactTrailing: _t('titulo', size: 14, weight: 700, color: accent),
    minimal: presetIcon('globe.europe.africa.fill', 'upload', accent: true),
    expanded: LiveExpanded(
      leading: _arc(96),
      center: LiveColumn([
        _t('titulo', size: 20, weight: 700, color: _white),
        _t('lugar', size: 13, muted: true, lines: 2),
        _t('tiempo', size: 13, weight: 600, color: accent),
      ], gap: 2),
    ),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: _ink,
        radius: 28,
        child: LivePadding(
          LiveRow([
            _arc(120),
            LiveColumn([
              _t('titulo', size: 24, weight: 700, color: _white),
              _t('lugar', size: 14, muted: true, lines: 2),
              _t('tiempo', size: 14, weight: 600, color: accent),
            ], gap: 2),
          ], gap: 16),
          all: 14,
        ),
      ),
    ),
    android: LiveAndroid(
      style: androidStyle,
      title: const LiveText.literal('Orbit'),
      text: const LiveText.format('{lugar} · {tiempo}'),
      chip: chip ?? const LiveChip.text('ISS'),
      progress: LiveGauge(
        value: const LiveBind('progreso'),
        style: LiveProgressStyle(color: accent),
      ),
    ),
  );
}

/// Electric car charging with the "glowing cable": a bar with a halo and
/// a card with a glowing border.
///
/// Data: `nivel` (text, for example `72 %`), `estado`, `restante`,
/// `potencia` and `progreso`.
final class ChargePreset extends LivePreset {
  const ChargePreset({
    this.androidStyle = LiveAndroidStyle.card,
    this.accent = const Color(0xFF30D158),
    this.glow = 10,
    this.compactIcon,
    this.chip,
  });

  /// Color of the bar, the border and the halo.
  final Color accent;

  /// Radius of the halo in pt (0 = no glow).
  final double glow;

  /// Icon or image of the compact and minimal island (a bolt by default).
  final LiveVisual? compactIcon;

  final LiveChip? chip;

  /// [LiveAndroidStyle.card] (the default) draws the same design on Android as on
  /// iOS; [LiveAndroidStyle.liveUpdate] uses the native template and lets
  /// Android 16 promote it to a Live Update.
  final LiveAndroidStyle androidStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'charge_glow',
    appName: 'Charge',
    accent: accent,
    icon: presetIcon('bolt.fill', 'zap'),
    countdown: false,
    progress: PresetProgress.bar,
    chip: chip ?? const LiveChip.text('72 %'),
    sample: const PresetSample(
      title: '72 %',
      subtitle: 'Charging · 38 min left',
      name: 'Charge',
      highlight: '48 kW',
      progress: 0.72,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'nivel': '72 %',
    'estado': 'Charging',
    'restante': '38 min left',
    'potencia': '48 kW',
    'progreso': 0.72,
  };

  LiveVisual get _bolt =>
      compactIcon ??
      LiveIcon.symbol(
        'bolt.fill',
        android: presetIcon('bolt.fill', 'zap').android,
        color: accent,
      );

  LiveNode get _cable => LiveProgress.bar(
    value: const LiveBind('progreso'),
    style: LiveProgressStyle(
      height: 8,
      color: accent,
      trackColor: const Color(0xFF2A2D33),
      glow: glow > 0 ? glow : null,
    ),
  );

  @override
  LiveLayout build() => LiveLayout(
    theme: const LiveTheme(
      accent: Color(0xFF0B0B0D),
      background: LiveBackground.accent,
    ),
    appLogo: presetIcon('bolt.fill', 'zap'),
    compactLeading: _bolt,
    compactTrailing: _t('nivel', size: 15, weight: 700, color: accent),
    minimal: _bolt,
    expanded: LiveExpanded(
      leading: _bolt,
      center: LiveColumn(
        [
          _t('nivel', size: 30, weight: 800, color: _white),
          _t('estado', size: 13, muted: true, lines: 1),
        ],
        align: LiveAlign.center,
        gap: 0,
      ),
      trailing: _t('potencia', size: 15, weight: 700, color: accent),
      bottom: LivePadding(_cable, vertical: 4),
    ),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: const Color(0xFF0B0B0D),
        radius: 22,
        border: glow > 0 ? accent : null,
        glow: glow > 0 ? glow : null,
        child: LivePadding(
          LiveColumn([
            LiveRow([
              _bolt,
              _t('estado', size: 13, color: const Color(0xFFB4B6BC)),
              const LiveSpacer(),
              _t('potencia', size: 13, weight: 700, color: accent),
            ], gap: 6),
            LiveRow([
              _t('nivel', size: 40, weight: 800, color: _white),
              const LiveSpacer(),
              _t('restante', size: 14, color: _white),
            ], align: LiveAlign.end),
            _cable,
          ], gap: 6),
          horizontal: 14,
          vertical: 10,
        ),
      ),
    ),
    android: LiveAndroid(
      style: androidStyle,
      title: const LiveBind('estado'),
      text: const LiveText.format('{restante} · {potencia}'),
      chip: chip ?? const LiveChip.text('72 %'),
    ),
  );
}

/// Summary of a ride with the fare split into colored segments: base,
/// service and tip.
///
/// Data: `titulo`, `total`, `base`, `servicio`, `propina` (numbers that
/// split the bar) and `baseTxt`, `servicioTxt`, `propinaTxt` (the same
/// amounts already written out).
final class FareSplitPreset extends LivePreset {
  const FareSplitPreset({
    this.accent = const Color(0xFF30D158),
    this.brand = 'Run',
    this.androidStyle = LiveAndroidStyle.card,
    this.chip,
  });

  /// Color of the tip.
  final Color accent;

  /// Name of the app, in italics at the top left.
  final String brand;

  /// On Android: `liveUpdate` (the default) with the split bar and the chip, or
  /// `card` with the full card.
  final LiveAndroidStyle androidStyle;

  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'fare_split',
    appName: brand,
    accent: accent,
    icon: presetIcon('car.fill', 'car'),
    countdown: false,
    progress: PresetProgress.none,
    chip: chip ?? const LiveChip.text('S/21.50'),
    sample: const PresetSample(
      title: 'Trip finished',
      subtitle: 'Total S/ 21.50',
      name: 'Trip',
      highlight: 'S/ 21.50',
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'titulo': 'Trip finished',
    'total': 'S/ 21.50',
    'base': 16,
    'servicio': 2.5,
    'propina': 3,
    'baseTxt': 'S/ 16.00',
    'servicioTxt': 'S/ 2.50',
    'propinaTxt': 'S/ 3.00',
  };

  static const _gray = Color(0xFF6B6E75);

  LiveNode get _bar => LiveSplitBar([
    const LiveSplitPart(LiveBind('base'), _white),
    const LiveSplitPart(LiveBind('servicio'), _gray),
    LiveSplitPart(const LiveBind('propina'), accent),
  ]);

  LiveNode _mark(Color c, double size) =>
      LiveText.literal(brand, size: size, weight: 800, color: c, italic: true);

  @override
  LiveLayout build() => LiveLayout(
    theme: const LiveTheme(
      accent: Color(0xFF0B0B0D),
      background: LiveBackground.accent,
    ),
    appLogo: presetIcon('car.fill', 'car'),
    compactLeading: LiveIcon.symbol(
      'car.fill',
      android: presetIcon('car.fill', 'car').android,
      color: accent,
    ),
    compactTrailing: _t('total', size: 15, weight: 700, color: _white),
    minimal: LiveIcon.symbol(
      'car.fill',
      android: presetIcon('car.fill', 'car').android,
      color: accent,
    ),
    expanded: LiveExpanded(
      leading: _mark(_white, 20),
      center: _t('titulo', size: 14, muted: true, lines: 1),
      trailing: _t('total', size: 20, weight: 800, color: _white),
      bottom: LiveColumn([
        _bar,
        LiveRow([
          LiveText.format('Base {baseTxt}', size: 12, color: _white),
          const LiveSpacer(),
          LiveText.format('Propina {propinaTxt}', size: 12, color: accent),
        ]),
      ], gap: 6),
    ),
    lockScreen: LiveLockScreen.custom(
      LiveColumn([
        LiveRow([
          _mark(_white, 20),
          const LiveSpacer(),
          _t('titulo', size: 13, color: const Color(0xFFB4B6BC)),
        ]),
        LiveRow([
          _t('total', size: 32, weight: 800, color: _white),
          const LiveSpacer(),
          LiveText.literal('Total', size: 13, color: const Color(0xFFB4B6BC)),
        ], align: LiveAlign.end),
        _bar,
        LiveRow([
          LiveText.format('Base {baseTxt}', size: 12, color: _white),
          const LiveSpacer(),
          LiveText.format(
            'Servicio {servicioTxt}',
            size: 12,
            color: const Color(0xFFB4B6BC),
          ),
          const LiveSpacer(),
          LiveText.format('Propina {propinaTxt}', size: 12, color: accent),
        ]),
      ], gap: 6),
    ),
    android: LiveAndroid(
      title: const LiveBind('titulo'),
      text: const LiveText.format(
        'Base {baseTxt} · Servicio {servicioTxt} · Propina {propinaTxt}',
      ),
      style: androidStyle,
      // En Android la barra usa colores que se leen sobre el fondo del sistema.
      progress: LiveSplitBar([
        const LiveSplitPart(LiveBind('base'), Color(0xFF5F6368)),
        const LiveSplitPart(LiveBind('servicio'), Color(0xFFB4B6BC)),
        LiveSplitPart(const LiveBind('propina'), accent),
      ]),
      chip: chip ?? const LiveChip.text('S/21.50'),
    ),
  );
}
