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

/// Escudo genérico azul y rojo (equipo local de ejemplo).
const liveDesignCrestAAsset = 'packages/live_island/assets/presets/crest_a.png';

/// Escudo genérico amarillo y azul marino (equipo visitante de ejemplo).
const liveDesignCrestBAsset = 'packages/live_island/assets/presets/crest_b.png';

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

/// Cómo se dibuja la barra de recogida.
enum RideBar {
  /// Línea continua de la salida al destino, con un marcador al final.
  line,

  /// Trazo discontinuo con marcadores intermedios.
  dotted,
}

/// Recogida de un viaje: tiempo, conductor con su auto, placa y una barra con
/// el auto avanzando hacia el punto de recogida.
///
/// La tarjeta clara usa la barra [RideBar.dotted] (punteada, con marcadores) y
/// la oscura [RideBar.line] (continua, con marcador final); [bar] cambia
/// cualquiera. Datos: `tiempo`, `titulo`, `subtitulo`, `placa`, `vehiculo`,
/// `nombre`, `progreso`. En la oscura el título va antes del tiempo
/// («Recogida en 2 min»); en la clara, después («2 min para la recogida»).
final class RidePickupPreset extends LivePreset {
  const RidePickupPreset({
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

  /// Tarjeta oscura en vez de clara.
  final bool dark;

  /// Color del tiempo y de lo avanzado en la tarjeta clara; de la isla.
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

  /// Una sola imagen con el conductor y su auto, sin fondo (reemplaza a
  /// [driverPhoto] y [carImage] en la tarjeta de bloqueo).
  final LiveImage? headerImage;

  /// Imagen del auto que avanza sobre la barra (vista desde arriba, sin fondo).
  final LiveImage? trackerImage;

  /// Ícono o imagen de la isla compacta y la mínima (por defecto un auto).
  final LiveVisual? compactIcon;

  /// Estilo de la barra; por defecto punteada en la clara y continua en la oscura.
  final RideBar? bar;

  /// Muestra al conductor y su auto arriba a la derecha.
  final bool showCar;

  /// Botones de la tarjeta de bloqueo y de Android.
  final List<LiveButton>? buttons;

  /// Chip de Android; por defecto el tiempo.
  final LiveChip? chip;

  RideBar get _bar => bar ?? (dark ? RideBar.line : RideBar.dotted);

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
      title: 'para la recogida',
      subtitle: 'Andrés llega en breve',
      name: 'Andrés',
      highlight: '2 min',
      progress: 0.34,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'tiempo': '2 min',
    'titulo': dark ? 'Recogida en' : 'para la recogida',
    'subtitulo': 'Andrés llega en breve',
    'placa': 'A1B-234',
    'vehiculo': 'Sedán plateado',
    'nombre': 'Andrés',
    'progreso': 0.34,
  };

  // Iniciales sobre un círculo del color de acento (no del tema: en la tarjeta
  // oscura el tema es casi negro).
  LiveNode get _driver =>
      driverPhoto != null
          ? LiveAvatar.photo(driverPhoto!, size: 34)
          : LiveBox(
            size: 34,
            radius: 17,
            color: accent,
            child: LiveText.literal(
              driverInitials,
              size: 15,
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
            width: 88,
            height: 46,
            shape: LiveShape.square,
          ),
      height: 24,
      background: LiveTrackerBackground.none,
    );
    if (_bar == RideBar.line) {
      return LiveProgress.bar(
        value: const LiveBind('progreso'),
        tracker: tracker,
        endIcon: LiveIcon.symbol(
          'record.circle',
          android: presetIcon('mappin', 'mappin').android,
          color: track,
          size: 18,
        ),
        style: LiveProgressStyle(height: 4, color: fill, trackColor: track),
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

    // Clara: «2 min para la recogida», subtítulo y, a la derecha, placa y auto.
    final lightBody = LiveRow([
      LiveColumn([
        LiveRow([
          _t('tiempo', size: 21, weight: 700, color: accent),
          _t('titulo', size: 21, weight: 700, color: ink),
        ], gap: 6),
        _t('subtitulo', size: 15, color: subtle),
      ], gap: 3),
      const LiveSpacer(),
      LiveColumn(
        [
          _t('placa', size: 20, weight: 700, color: ink),
          _t('vehiculo', size: 14, color: subtle),
        ],
        align: LiveAlign.end,
        gap: 3,
      ),
    ], align: LiveAlign.end);

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
      expanded: LiveExpanded(
        leading: _driver,
        center: LiveColumn([
          LiveRow(
            dark
                ? [
                  _t('titulo', size: 17, weight: 700, color: _white, lines: 1),
                  _t('tiempo', size: 17, weight: 700, color: _white),
                ]
                : [
                  _t('tiempo', size: 17, weight: 700, color: accent),
                  _t('titulo', size: 17, weight: 700, color: _white, lines: 1),
                ],
            gap: 5,
          ),
          const LiveText.format(
            '{placa} · {vehiculo}',
            size: 13,
            muted: true,
            lines: 1,
          ),
        ], gap: 2),
        bottom: LiveColumn([
          _progress(_white, const Color(0xFF6B6E75)),
          if ((buttons ?? const []).isNotEmpty) LiveRow(buttons!),
        ], gap: 10),
      ),
      lockScreen: LiveLockScreen.custom(card),
      android: LiveAndroid(
        title:
            dark
                ? const LiveText.format('{titulo} {tiempo}')
                : const LiveText.format('{tiempo} {titulo}'),
        text: const LiveText.format('{subtitulo} · {placa}'),
        chip: chip ?? const LiveChip.text('2 min'),
      ),
    );
  }
}

/// Pedido para recoger en tienda: tres pasos con íconos (recibido, preparando,
/// listo) donde el paso actual crece y se pinta de blanco.
///
/// Datos: `titulo`, `subtitulo`, `corto` (una palabra para la isla compacta),
/// `etapa` (0, 1 o 2), `progreso`.
final class StorePickupPreset extends LivePreset {
  const StorePickupPreset({
    this.accent = const Color(0xFF1E3932),
    this.stepColor = const Color(0xFF00A862),
    this.store = 'Recogida en tienda',
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
      title: 'Pedido en preparación',
      subtitle: 'Estamos preparando tu pedido con cuidado',
      name: 'Tienda',
      progress: 0.5,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'titulo': 'Pedido en preparación',
    'subtitulo': 'Estamos preparando tu pedido con cuidado',
    'corto': 'Preparando',
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
    this.unit = 'Kilómetros',
    this.timeLabel = 'Tiempo',
    this.brand = 'Sprint',
    this.buttons,
    this.chip,
  });

  /// Color de la tarjeta.
  final Color accent;

  /// Unidad bajo la distancia.
  final String unit;

  /// Etiqueta bajo el tiempo.
  final String timeLabel;

  /// Nombre de la app, arriba a la derecha de la tarjeta.
  final String brand;

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
    chip: chip ?? const LiveChip.text('4,72'),
    sample: const PresetSample(
      title: '4,72',
      subtitle: 'Kilómetros',
      name: 'Tiempo',
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
    android: LiveAndroid(
      title: const LiveText.format('{distancia} · {tiempo}'),
      chip: chip ?? const LiveChip.text('4,72'),
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
    this.homeLabel = 'Local',
    this.awayLabel = 'Visitante',
    this.link = 'Ver estadísticas',
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
      title: 'Leones 3 – 1 Halcones',
      subtitle: 'Copa del mundo',
      name: 'Partido',
      highlight: '6:15',
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'local': 'Leones',
    'visitante': 'Halcones',
    'golesLocal': '3',
    'golesVisitante': '1',
    'minuto': '6:15',
    'torneo': 'Copa del mundo',
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
      title: 'VOLT 219.40',
      subtitle: 'Voltio S.A.',
      name: 'Bolsa',
      highlight: '+1.24%',
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'simbolo': 'VOLT',
    'nombre': 'Voltio S.A.',
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
          ], gap: 4),
          horizontal: 14,
          vertical: 8,
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
      title: 'LIM → MAD',
      subtitle: 'Aterriza en 55 min',
      name: 'RA234',
      highlight: 'A tiempo',
      progress: 0.72,
    ),
  );

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'vuelo': 'RA 234',
    'estado': 'A tiempo',
    'origen': 'LIM',
    'destino': 'MAD',
    'aterriza': 'Aterriza en 55 min',
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

/// Viaje visto por el conductor: a quién recoger, la tarifa y cuánto falta.
///
/// Es la contraparte de [RidePickupPreset]: la misma barra con el auto, pero
/// con la tarifa en grande y un botón «Llegué». Datos: `pasajero`, `ruta`,
/// `tarifa`, `tiempo`, `distancia`, `progreso`.
final class RideDriverPreset extends LivePreset {
  const RideDriverPreset({
    this.accent = const Color(0xFF30D158),
    this.brand = 'Run Conductor',
    this.passengerInitials = 'A',
    this.passengerPhoto,
    this.trackerImage,
    this.compactIcon,
    this.buttons,
    this.chip,
  });

  /// Color de la tarifa y de lo avanzado.
  final Color accent;

  /// Nombre de la app, arriba a la izquierda de la tarjeta.
  final String brand;

  /// Iniciales del pasajero (si no hay [passengerPhoto]).
  final String passengerInitials;

  /// Foto circular del pasajero.
  final LiveImage? passengerPhoto;

  /// Imagen del auto que avanza sobre la barra (vista desde arriba, sin fondo).
  final LiveImage? trackerImage;

  /// Ícono o imagen de la isla compacta y la mínima (por defecto un auto).
  final LiveVisual? compactIcon;

  /// Botones de la tarjeta de bloqueo y de Android; por defecto «Llegué».
  final List<LiveButton>? buttons;

  /// Chip de Android; por defecto la tarifa.
  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'ride_driver',
    appName: brand,
    accent: accent,
    icon: presetIcon('car.fill', 'car'),
    countdown: false,
    progress: PresetProgress.bar,
    buttons: _buttons,
    chip: chip ?? const LiveChip.text('S/ 18.50'),
    sample: const PresetSample(
      title: 'Recoge a Ana R.',
      subtitle: 'Av. Arequipa → Miraflores',
      name: 'Ana',
      highlight: 'S/ 18.50',
      progress: 0.4,
    ),
  );

  List<LiveButton> get _buttons =>
      buttons ??
      [presetButton('Llegué', presetIcon('mappin', 'mappin'), id: 'llegue')];

  @override
  Map<String, Object?> sampleState({DateTime? now}) => {
    'pasajero': 'Ana R.',
    'ruta': 'Av. Arequipa → Miraflores',
    'tarifa': 'S/ 18.50',
    'tiempo': '3 min',
    'distancia': '0.8 km',
    'progreso': 0.4,
  };

  LiveVisual get _passenger =>
      passengerPhoto != null
          ? LiveAvatar.photo(passengerPhoto!, size: 40)
          : LiveAvatar(passengerInitials, size: 40);

  LiveVisual get _compact =>
      compactIcon ?? presetIcon('car.fill', 'car', accent: true);

  LiveNode get _bar => LiveProgress.bar(
    value: const LiveBind('progreso'),
    tracker: LiveTracker(
      trackerImage ??
          LiveImage.asset(
            liveDesignCarTopAsset,
            width: 88,
            height: 46,
            shape: LiveShape.square,
          ),
      height: 26,
      background: LiveTrackerBackground.none,
    ),
    endIcon: LiveIcon.symbol(
      'record.circle',
      android: presetIcon('mappin', 'mappin').android,
      color: const Color(0xFF6B6E75),
      size: 18,
    ),
    style: LiveProgressStyle(
      height: 4,
      color: accent,
      trackColor: const Color(0xFF6B6E75),
    ),
  );

  @override
  LiveLayout build() => LiveLayout(
    theme: LiveTheme(accent: accent),
    appLogo: presetIcon('car.fill', 'car'),
    compactLeading: _compact,
    compactTrailing: _t('tarifa', size: 15, weight: 700, color: accent),
    minimal: _compact,
    expanded: LiveExpanded(
      leading: _passenger,
      center: LiveColumn([
        LiveText.format(
          'Recoge a {pasajero}',
          size: 16,
          weight: 700,
          color: _white,
          lines: 1,
        ),
        _t('ruta', size: 13, muted: true, lines: 1),
      ], gap: 2),
      trailing: _t('tarifa', size: 17, weight: 800, color: accent),
      bottom: _bar,
    ),
    lockScreen: LiveLockScreen.custom(
      LiveBox(
        color: const Color(0xFF16181C),
        radius: 22,
        child: LivePadding(
          LiveColumn([
            LiveRow([
              LiveText.literal(brand, size: 17, weight: 800, color: _white),
              const LiveSpacer(),
              ..._buttons,
            ]),
            LiveRow([
              LiveColumn([
                LiveText.format(
                  'Recoge a {pasajero}',
                  size: 21,
                  weight: 700,
                  color: _white,
                ),
                LiveText.format(
                  '{tiempo} · {distancia}',
                  size: 13,
                  color: const Color(0xFFB4B6BC),
                ),
              ], gap: 2),
              const LiveSpacer(),
              _t('tarifa', size: 28, weight: 800, color: accent),
            ], align: LiveAlign.end),
            _bar,
          ], gap: 6),
          horizontal: 14,
          vertical: 8,
        ),
      ),
    ),
    android: LiveAndroid(
      title: const LiveText.format('Recoge a {pasajero}'),
      text: const LiveText.format('{tiempo} · {distancia} · {tarifa}'),
      chip: chip ?? const LiveChip.text('S/ 18.50'),
    ),
  );
}
