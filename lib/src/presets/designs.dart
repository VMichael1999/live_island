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

/// Auto visto desde arriba, para avanzar sobre una barra.
const liveDesignCarTopAsset = 'packages/live_island/assets/presets/car_top.png';

/// Auto visto de lado, para acompañar al conductor.
const liveDesignCarSideAsset =
    'packages/live_island/assets/presets/car_side.png';

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

/// Recogida de un viaje: tiempo, conductor con su auto, matrícula y una barra
/// de trazo discontinuo con el auto avanzando hacia el punto de recogida.
///
/// Con [dark] la tarjeta de bloqueo es oscura y la barra blanca; si no, clara
/// con la barra del color de acento. Datos: `tiempo`, `titulo`, `subtitulo`,
/// `placa`, `vehiculo`, `nombre`, `progreso`.
final class RidePickupPreset extends LivePreset {
  const RidePickupPreset({
    this.dark = false,
    this.accent = const Color(0xFF1F5EFF),
    this.brand = 'Rides',
    this.driverInitials = 'A',
    this.driverPhoto,
    this.carImage,
    this.brandLogo,
    this.headerImage,
    this.trackerImage,
    this.showCar = true,
    this.buttons,
    this.chip,
  });

  /// Tarjeta oscura (barra blanca) en vez de clara (barra de acento).
  final bool dark;

  /// Color del tiempo y de la barra en la tarjeta clara.
  final Color accent;

  /// Nombre de la app, arriba a la izquierda de la tarjeta.
  final String brand;

  /// Iniciales del conductor (si no hay [driverPhoto]).
  final String driverInitials;

  /// Foto circular del conductor.
  final LiveImage? driverPhoto;

  /// Imagen del auto junto al conductor; por defecto la que trae el paquete.
  final LiveImage? carImage;

  /// Logotipo en lugar del nombre de la app, arriba a la izquierda.
  final LiveImage? brandLogo;

  /// Una sola imagen con el conductor y su auto (reemplaza a [driverPhoto] y
  /// [carImage] en la tarjeta de bloqueo).
  final LiveImage? headerImage;

  /// Imagen del auto que avanza sobre la barra (vista desde arriba).
  final LiveImage? trackerImage;

  /// Muestra al conductor y su auto arriba a la derecha.
  final bool showCar;

  /// Botones de la tarjeta de bloqueo y de Android.
  final List<LiveButton>? buttons;

  /// Chip de Android; por defecto el tiempo.
  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: dark ? 'ride_pickup_dark' : 'ride_pickup',
    appName: brand,
    accent: accent,
    icon: presetIcon('car.fill', 'car'),
    countdown: false,
    progress: PresetProgress.bar,
    buttons: buttons ?? const [],
    chip: chip ?? const LiveChip.text('1 min'),
    sample: const PresetSample(
      title: 'until pickup',
      subtitle: 'Anderson is arriving soon',
      name: 'Anderson',
      highlight: '1 min',
      progress: 0.34,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'tiempo': '1 min',
    'titulo': 'until pickup',
    'subtitulo': 'Anderson is arriving soon',
    'placa': '7NLR004',
    'vehiculo': 'Silver Honda Civic',
    'nombre': 'Anderson',
    'progreso': 0.34,
  };

  LiveVisual get _driver =>
      driverPhoto != null
          ? LiveAvatar.photo(driverPhoto!, size: 38)
          : LiveAvatar(driverInitials, size: 38);

  LiveImage get _car =>
      carImage ??
      LiveImage.asset(
        liveDesignCarSideAsset,
        width: 110,
        height: 46,
        shape: LiveShape.square,
        size: 92,
      );

  LiveNode _progress(Color fill, Color track) => LiveProgress.bar(
    value: const LiveBind('progreso'),
    tracker: LiveTracker(
      trackerImage ??
          LiveImage.asset(
            liveDesignCarTopAsset,
            width: 88,
            height: 46,
            shape: LiveShape.square,
          ),
      height: 24,
      background: LiveTrackerBackground.none,
    ),
    endIcon: presetIcon('mappin', 'mappin'),
    style: LiveProgressStyle(
      height: 4,
      color: fill,
      trackColor: track,
      dashed: true,
    ),
  );

  @override
  LiveLayout build() {
    final ink = dark ? _white : _ink;
    final fill = dark ? _white : accent;
    final track = dark ? const Color(0xFF66686E) : const Color(0xFFB4B4B9);

    LiveNode card(Color text, Color timeColor) => LiveColumn([
      LiveRow([
        brandLogo ??
            LiveText.literal(brand, size: 20, weight: 800, color: text),
        const LiveSpacer(),
        if (showCar && headerImage != null)
          headerImage!
        else if (showCar)
          LiveRow([_driver, _car], gap: 0),
      ]),
      LiveRow([
        LiveColumn([
          LiveRow([
            _t('tiempo', size: 22, weight: 700, color: timeColor),
            _t('titulo', size: 22, weight: 700, color: text),
          ], gap: 5),
          _t('subtitulo', size: 14, color: text),
        ], gap: 3),
        const LiveSpacer(),
        LiveColumn(
          [
            _t('placa', size: 20, weight: 700, color: text),
            _t('vehiculo', size: 14, color: text),
          ],
          align: LiveAlign.end,
          gap: 3,
        ),
      ], align: LiveAlign.end),
      _progress(fill, track),
      if ((buttons ?? const []).isNotEmpty) LiveRow(buttons!),
    ], gap: 10);

    return LiveLayout(
      theme: LiveTheme(
        accent: accent,
        background: dark ? LiveBackground.system : LiveBackground.light,
      ),
      appLogo: presetIcon('car.fill', 'car'),
      compactLeading: presetIcon('car.fill', 'car', accent: true),
      compactTrailing: _t('tiempo', size: 15, weight: 600, accent: true),
      minimal: presetIcon('car.fill', 'car', accent: true),
      expanded: LiveExpanded(
        leading: _driver,
        center: LiveColumn([
          LiveRow([
            _t('tiempo', size: 16, weight: 700, accent: true),
            _t('titulo', size: 16, weight: 700),
          ], gap: 5),
          _t('subtitulo', size: 13, muted: true),
        ], gap: 2),
        trailing: _t('placa', size: 15, weight: 700),
        bottom: LiveColumn([
          _progress(_white, const Color(0xFF66686E)),
          if ((buttons ?? const []).isNotEmpty) LiveRow(buttons!),
        ], gap: 10),
      ),
      lockScreen: LiveLockScreen.custom(
        dark
            // Tarjeta oscura propia: se ve igual con el sistema en claro o en oscuro.
            ? LiveBox(
              color: const Color(0xFF16181C),
              radius: 20,
              child: LivePadding(card(ink, _white), all: 4),
            )
            : card(ink, accent),
      ),
      android: LiveAndroid(
        title: const LiveText.format('{tiempo} {titulo}'),
        text: const LiveText.format('{subtitulo} · {placa}'),
        chip: chip ?? const LiveChip.text('1 min'),
      ),
    );
  }
}

/// Pedido para recoger en tienda: tres pasos con íconos (recibido, preparando,
/// listo) donde el paso actual crece y se pinta de blanco.
///
/// Datos: `titulo`, `subtitulo`, `etapa` (0, 1 o 2), `progreso`.
final class StorePickupPreset extends LivePreset {
  const StorePickupPreset({
    this.accent = const Color(0xFF1E3932),
    this.stepColor = const Color(0xFF00A862),
    this.store = 'In store pickup',
    this.brandLogo,
    this.people,
    this.buttons,
    this.chip,
  });

  /// Fondo de la tarjeta.
  final Color accent;

  /// Color de los pasos que no son el actual.
  final Color stepColor;

  /// Cabecera de la tarjeta.
  final String store;

  /// Logotipo junto a la cabecera (por defecto un ícono).
  final LiveImage? brandLogo;

  /// Personas que reciben el pedido (iniciales); por defecto dos.
  final List<String>? people;

  final List<LiveButton>? buttons;
  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'store_pickup',
    appName: store,
    accent: accent,
    icon: presetIcon('cup.and.saucer.fill', 'coffee'),
    countdown: false,
    progress: PresetProgress.none,
    buttons: buttons ?? const [],
    chip: chip ?? const LiveChip.text('Preparando'),
    sample: const PresetSample(
      title: 'Order in progress',
      subtitle: 'We are handcrafting your order',
      name: 'Store',
      progress: 0.5,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'titulo': 'Order in progress',
    'subtitulo': 'We are handcrafting your order',
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
    ], gap: 10);
  }

  @override
  LiveLayout build() {
    final steps = _rail;
    return LiveLayout(
      theme: LiveTheme(accent: accent, background: LiveBackground.accent),
      appLogo: presetIcon('cup.and.saucer.fill', 'coffee'),
      compactLeading: presetIcon('cup.and.saucer.fill', 'coffee'),
      compactTrailing: _t('titulo', size: 13, weight: 600, lines: 1),
      minimal: presetIcon('cup.and.saucer.fill', 'coffee'),
      expanded: LiveExpanded(
        center: LiveColumn([
          _t('titulo', size: 20, weight: 700),
          _t('subtitulo', size: 13, muted: true),
        ], gap: 3),
        trailing: steps,
      ),
      lockScreen: LiveLockScreen.custom(
        LiveColumn([
          LiveRow([
            LiveRow([
              brandLogo ?? presetIcon('cup.and.saucer.fill', 'coffee'),
              LiveText.literal(store, size: 14, color: _white),
            ], gap: 8),
            const LiveSpacer(),
            LiveRow([
              for (final p in people ?? const ['S', 'D'])
                LiveAvatar(p, size: 24),
            ], gap: 0),
          ]),
          LiveRow([
            LiveColumn([
              _t('titulo', size: 24, weight: 700, color: _white),
              _t('subtitulo', size: 13, color: const Color(0xFFB7CBC4)),
            ], gap: 3),
            const LiveSpacer(),
            steps,
          ]),
          if ((buttons ?? const []).isNotEmpty) LiveRow(buttons!),
        ], gap: 12),
      ),
      android: LiveAndroid(
        title: const LiveBind('titulo'),
        text: const LiveBind('subtitulo'),
        chip: chip ?? const LiveChip.text('Preparando'),
      ),
    );
  }
}

/// Carrera o entrenamiento: distancia grande, tiempo y barra de meta.
///
/// Datos: `distancia`, `tiempo`, `progreso`.
final class RunPreset extends LivePreset {
  const RunPreset({
    this.accent = const Color(0xFF45C8FF),
    this.unit = 'Miles',
    this.timeLabel = 'Time',
    this.brandMark,
    this.buttons,
    this.chip,
  });

  /// Color de la tarjeta.
  final Color accent;

  /// Unidad bajo la distancia.
  final String unit;

  /// Etiqueta bajo el tiempo.
  final String timeLabel;

  /// Marca o logotipo arriba a la derecha de la tarjeta.
  final LiveImage? brandMark;

  final List<LiveButton>? buttons;
  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'run',
    appName: 'Run',
    accent: accent,
    icon: presetIcon('figure.run', 'flag'),
    countdown: false,
    progress: PresetProgress.bar,
    buttons: buttons ?? const [],
    chip: chip ?? const LiveChip.text('2.94'),
    sample: const PresetSample(
      title: '2.94',
      subtitle: 'Miles',
      name: 'Time',
      highlight: '25:38',
      progress: 0.78,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'distancia': '2.94',
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
              if (brandMark != null) brandMark!,
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
    android: LiveAndroid(
      title: const LiveText.format('{distancia} · {tiempo}'),
      chip: chip ?? const LiveChip.text('2.94'),
    ),
  );
}

/// Marcador de un partido: escudos, goles en un recuadro, minuto y torneo.
///
/// Datos: `local`, `visitante`, `golesLocal`, `golesVisitante`, `minuto`,
/// `torneo`, `progreso`.
final class MatchPreset extends LivePreset {
  const MatchPreset({
    this.accent = const Color(0xFF1B5E20),
    this.homeCrest,
    this.awayCrest,
    this.homeLabel = 'Home',
    this.awayLabel = 'Guest',
    this.link = 'See stats',
    this.chip,
  });

  final Color accent;

  /// Escudo del equipo local (imagen propia).
  final LiveImage? homeCrest;

  /// Escudo del equipo visitante.
  final LiveImage? awayCrest;

  /// Etiqueta bajo el nombre del local.
  final String homeLabel;

  /// Etiqueta bajo el nombre del visitante.
  final String awayLabel;

  /// Texto del enlace bajo el minuto.
  final String link;

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
      title: 'PSG 3 – 1 Chelsea',
      subtitle: 'World cup',
      name: 'Match',
      highlight: '6:15',
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'local': 'PSG',
    'visitante': 'Chelsea',
    'golesLocal': '3',
    'golesVisitante': '1',
    'minuto': '6:15',
    'torneo': 'World cup',
    'progreso': 0.07,
  };

  LiveNode _side(LiveImage? crest, String field, String label) => LiveColumn([
    crest ?? presetIcon('trophy.fill', 'trophy', accent: true),
    _t(field, size: 18, weight: 700, color: _white),
    LiveText.literal(label, size: 14, weight: 700, color: _white),
  ], gap: 2);

  @override
  LiveLayout build() {
    final score = LiveRow([
      _t('golesLocal', size: 46, weight: 800, color: _white),
      LiveText.literal(':', size: 46, weight: 800, color: _white),
      _t('golesVisitante', size: 46, weight: 800, color: _white),
    ], gap: 6);
    final centre = LiveColumn([
      LiveBox(child: score, radius: 12, color: const Color(0xFF202020)),
      _t('minuto', size: 16, color: _white),
      LiveText.literal(link, size: 16, color: _white),
      _t('torneo', size: 14, color: _white),
    ], gap: 4);
    return LiveLayout(
      theme: LiveTheme(accent: accent),
      appLogo: presetIcon('trophy.fill', 'trophy'),
      compactLeading:
          homeCrest ?? presetIcon('trophy.fill', 'trophy', accent: true),
      compactTrailing: LiveRow([
        _t('golesLocal', size: 15, weight: 700, accent: true),
        LiveText.literal('–', size: 15, weight: 700, accent: true),
        _t('golesVisitante', size: 15, weight: 700, accent: true),
      ], gap: 2),
      minimal: presetIcon('trophy.fill', 'trophy', accent: true),
      expanded: LiveExpanded(
        leading: _side(homeCrest, 'local', homeLabel),
        center: centre,
        trailing: _side(awayCrest, 'visitante', awayLabel),
      ),
      // Tarjeta negra propia (como la isla), igual con el sistema en claro o en oscuro.
      lockScreen: LiveLockScreen.custom(
        LiveBox(
          color: const Color(0xFF000000),
          radius: 28,
          child: LivePadding(
            LiveRow([
              _side(homeCrest, 'local', homeLabel),
              const LiveSpacer(),
              centre,
              const LiveSpacer(),
              _side(awayCrest, 'visitante', awayLabel),
            ], align: LiveAlign.end),
            all: 8,
          ),
        ),
      ),
      android: LiveAndroid(
        title: const LiveText.format(
          '{local} {golesLocal} – {golesVisitante} {visitante}',
        ),
        text: const LiveBind('torneo'),
        chip: chip ?? const LiveChip.text('3–1'),
      ),
    );
  }
}

const _up = Color(0xFF30D158);

/// Cotización de una acción: símbolo, precio, variación y gráfica de línea.
///
/// Datos: `simbolo`, `nombre`, `precio`, `cambio` (texto, por ejemplo
/// `+1.24%`) y `serie` (los últimos precios con [liveSeries]).
final class StockPreset extends LivePreset {
  const StockPreset({this.accent = _up, this.brandLogo, this.chip});

  /// Color de la línea y de la variación (verde si sube, rojo si baja).
  final Color accent;

  /// Logotipo de la empresa.
  final LiveImage? brandLogo;

  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'stock',
    appName: 'Bolsa',
    accent: accent,
    icon: presetIcon('chart.line.uptrend.xyaxis', 'landmark'),
    countdown: false,
    progress: PresetProgress.none,
    androidPromotable: false,
    chip: chip ?? const LiveChip.text('+1.2%'),
    sample: const PresetSample(
      title: 'TSLA 219.40',
      subtitle: 'Tesla, Inc.',
      name: 'Bolsa',
      highlight: '+1.24%',
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'simbolo': 'TSLA',
    'nombre': 'Tesla, Inc.',
    'precio': '219.40',
    'cambio': '+1.24%',
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
          ], gap: 8),
          all: 14,
        ),
      ),
    ),
    android: LiveAndroid(
      title: const LiveText.format('{simbolo}'),
      text: const LiveBind('cambio'),
      chip: chip ?? const LiveChip.text('+1.2%'),
    ),
  );
}

/// Vuelo con la ruta curva entre dos aeropuertos y el avión avanzando.
///
/// Datos: `vuelo`, `estado`, `origen`, `destino`, `aterriza` y `progreso`.
final class FlightPathPreset extends LivePreset {
  const FlightPathPreset({
    this.accent = const Color(0xFF30D158),
    this.carrier,
    this.chip,
  });

  /// Color de lo recorrido, del avión y del estado.
  final Color accent;

  /// Logotipo de la aerolínea.
  final LiveImage? carrier;

  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'flightpath',
    appName: 'Vuelo',
    accent: accent,
    icon: presetIcon('airplane', 'plane'),
    countdown: false,
    progress: PresetProgress.bar,
    chip: chip ?? const LiveChip.text('55 min'),
    sample: const PresetSample(
      title: 'SFO → JFK',
      subtitle: 'Landing in 55m',
      name: 'FL234',
      highlight: 'On time',
      progress: 0.72,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'vuelo': 'FL234',
    'estado': 'On Time',
    'origen': 'SFO',
    'destino': 'JFK',
    'aterriza': 'Landing in 55m',
    'progreso': 0.72,
  };

  LiveNode get _route => LiveFlightPath(
    value: const LiveBind('progreso'),
    height: 46,
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
              if (carrier != null) carrier!,
              _t('vuelo', size: 15, weight: 700, color: _white),
              const LiveSpacer(),
              _t('estado', size: 13, weight: 600, color: accent),
            ]),
            LiveRow([
              _t('origen', size: 34, weight: 700, color: _white),
              const LiveSpacer(),
              _t('destino', size: 34, weight: 700, color: _white),
            ]),
            _route,
            _t('aterriza', size: 14, color: _white),
          ], gap: 6),
          all: 14,
        ),
      ),
    ),
    android: LiveAndroid(
      title: const LiveText.format('{vuelo}'),
      text: const LiveText.format('{origen} → {destino} · {aterriza}'),
      chip: chip ?? const LiveChip.text('55 min'),
      progress: LiveFlightPath(
        value: const LiveBind('progreso'),
        tracker: presetIcon('airplane', 'plane'),
        style: LiveProgressStyle(color: accent),
      ),
    ),
  );
}

/// Órbita: un arco con un punto que avanza (la ISS, un satélite, un
/// parquímetro). El arco es un [LiveGauge], así que `sweep` lo cambia.
///
/// Datos: `titulo`, `lugar`, `tiempo` y `progreso`.
final class OrbitPreset extends LivePreset {
  const OrbitPreset({
    this.accent = const Color(0xFF64D2FF),
    this.sweep = 180,
    this.chip,
  });

  final Color accent;

  /// Grados que abarca el arco.
  final double sweep;

  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'orbit',
    appName: 'Órbita',
    accent: accent,
    icon: presetIcon('globe.europe.africa.fill', 'upload'),
    countdown: false,
    progress: PresetProgress.bar,
    chip: chip ?? const LiveChip.text('ISS'),
    sample: const PresetSample(
      title: 'ISS',
      subtitle: 'Sobre el océano Pacífico',
      name: 'Órbita',
      highlight: '27 600 km/h',
      progress: 0.38,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'titulo': 'ISS',
    'lugar': 'Sobre el océano Pacífico',
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
      ], gap: 2),
      trailing: _t('tiempo', size: 13, weight: 600, color: accent),
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
      title: const LiveText.literal('Órbita'),
      text: const LiveText.format('{lugar} · {tiempo}'),
      chip: chip ?? const LiveChip.text('ISS'),
      progress: LiveGauge(
        value: const LiveBind('progreso'),
        style: LiveProgressStyle(color: accent),
      ),
    ),
  );
}
