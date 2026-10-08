import 'dart:ui' show Color;

import 'package:live_island/live_island.dart';

/// Un caso de ejemplo: diseño y estado inicial.
class Demo {
  const Demo(this.id, this.label, this.app, this.layout, this.state);

  final String id, label, app;
  final LiveLayout layout;

  /// Estado nuevo (las cuentas regresivas arrancan al llamarlo).
  final Map<String, Object?> Function() state;
}

final demos = <Demo>[
  Demo(
    'taxi',
    'Taxi',
    'Taxi Ya',
    _taxi(),
    () => {
      'titulo': 'Tu conductor está en camino',
      'subtitulo': 'Toyota Yaris gris · ABC-123',
      'nombre': 'Carlos M.',
      'llegaA': DateTime.now().add(const Duration(minutes: 6)),
      'progreso': 0.45,
    },
  ),
  Demo(
    'delivery',
    'Delivery de comida',
    'Come Ya',
    _delivery(),
    () => {
      'titulo': 'Tu pedido va en camino',
      'subtitulo': 'Pollería La Brasa · 2 productos',
      'nombre': 'Luis, repartidor',
      'llegaA': DateTime.now().add(const Duration(minutes: 12)),
      'progreso': 0.62,
    },
  ),
  Demo(
    'parking',
    'Estacionamiento',
    'Parquea',
    _parking(),
    () => {
      'titulo': 'Estacionamiento activo',
      'subtitulo': 'Zona azul · Av. Larco 400',
      'nombre': 'Placa ABC-123',
      'llegaA': DateTime.now().add(const Duration(minutes: 45)),
      'progreso': 0.35,
    },
  ),
];

LiveText _title() => LiveText(bind('titulo'), size: 15, weight: 600, lines: 2);
LiveText _subtitle() => LiveText(bind('subtitulo'), size: 13, muted: true);

LiveColumn _centerText() => LiveColumn([_title(), _subtitle()]);

LiveColumn _highlightAndName() => LiveColumn([
  LiveText.from(
    LiveText.countdown(bind('llegaA')),
    size: 22,
    weight: 700,
    accent: true,
  ),
  LiveText(bind('nombre'), size: 12, muted: true),
], align: LiveAlign.end);

LiveText _compactHighlight() => LiveText.from(
  LiveText.countdown(bind('llegaA')),
  size: 15,
  weight: 600,
  accent: true,
);

LiveLayout _taxi() => LiveLayout(
  theme: const LiveTheme(accent: Color(0xFF1F6FEB)),
  appLogo: LiveImage.asset('assets/live/logo.png', fit: LiveFit.cover),
  compactLeading: const LiveAvatar('CM'),
  compactTrailing: _compactHighlight(),
  minimal: const LiveAvatar('CM'),
  expanded: LiveExpanded(
    leading: const LiveAvatar('CM'),
    center: _centerText(),
    trailing: _highlightAndName(),
    bottom: LiveColumn([
      LiveSegments(
        value: bind('progreso'),
        labels: const ['Asignado', 'En camino', 'Llegó'],
        points: true,
        tracker: LiveTracker(
          LiveImage.asset('assets/live/car.png'),
          height: 24,
          background: LiveTrackerBackground.none,
        ),
        endIcon: const LiveIcon.symbol('mappin'),
      ),
      LiveRow([
        LiveButton(
          id: 'llamar',
          label: 'Llamar',
          icon: const LiveIcon.symbol('phone.fill'),
        ),
        LiveButton(
          id: 'compartir',
          label: 'Compartir',
          icon: const LiveIcon.symbol('square.and.arrow.up'),
        ),
      ]),
    ], gap: 12),
  ),
  lockScreen: const LiveLockScreen.sameAsExpanded(),
  android: LiveAndroid(
    title: bind('titulo'),
    text: const LiveText.format('{subtitulo} · {nombre}'),
    chip: LiveChip.countdown(bind('llegaA')),
  ),
);

LiveLayout _delivery() => LiveLayout(
  theme: const LiveTheme(accent: Color(0xFFE4572E)),
  appLogo: const LiveIcon.symbol('fork.knife'),
  compactLeading: const LiveIcon.symbol('fork.knife', accent: true),
  compactTrailing: _compactHighlight(),
  minimal: const LiveIcon.symbol('fork.knife', accent: true),
  expanded: LiveExpanded(
    leading: const LiveBox(
      child: LiveIcon.symbol('fork.knife', accent: true),
      size: 46,
      radius: 14,
      tint: 0.22,
    ),
    center: _centerText(),
    trailing: _highlightAndName(),
    bottom: LiveColumn([
      LiveSegments(
        value: bind('progreso'),
        labels: const ['Confirmado', 'Preparando', 'En camino', 'Entregado'],
        points: true,
        tracker: const LiveIcon.symbol('bicycle'),
        endIcon: const LiveIcon.symbol('house.fill'),
      ),
      LiveRow([
        LiveButton(
          id: 'llamar',
          label: 'Llamar',
          icon: const LiveIcon.symbol('phone.fill'),
        ),
        LiveButton(
          id: 'ver_mapa',
          label: 'Ver mapa',
          icon: const LiveIcon.symbol('mappin'),
        ),
      ]),
    ], gap: 12),
  ),
  lockScreen: const LiveLockScreen.sameAsExpanded(),
  android: LiveAndroid(
    title: bind('titulo'),
    text: const LiveText.format('{subtitulo} · {nombre}'),
    chip: LiveChip.countdown(bind('llegaA')),
  ),
);

LiveLayout _parking() => LiveLayout(
  theme: const LiveTheme(accent: Color(0xFF0277BD)),
  appLogo: const LiveIcon.symbol('parkingsign.circle.fill'),
  compactLeading: const LiveIcon.symbol(
    'parkingsign.circle.fill',
    accent: true,
  ),
  compactTrailing: _compactHighlight(),
  minimal: LiveProgress.ring(
    value: bind('progreso'),
    child: const LiveIcon.symbol('parkingsign.circle.fill', accent: true),
  ),
  expanded: LiveExpanded(
    leading: const LiveBox(
      child: LiveIcon.symbol('parkingsign.circle.fill', accent: true),
      size: 46,
      radius: 14,
      tint: 0.22,
    ),
    center: _centerText(),
    trailing: LiveProgress.ring(value: bind('progreso'), size: 46),
    bottom: LiveColumn([
      LiveRow([
        const LiveSpacer(),
        LiveText.from(
          LiveText.countdown(bind('llegaA')),
          size: 12,
          muted: true,
        ),
        const LiveText.literal('·', size: 12, muted: true),
        LiveText(bind('nombre'), size: 12, muted: true),
        const LiveSpacer(),
      ], gap: 4),
      LiveRow([
        LiveButton(
          id: 'mas_15_min',
          label: '+15 min',
          icon: const LiveIcon.symbol('plus'),
        ),
        LiveButton(
          id: 'terminar',
          label: 'Terminar',
          icon: const LiveIcon.symbol('xmark'),
        ),
      ]),
    ], gap: 12),
  ),
  lockScreen: const LiveLockScreen.sameAsExpanded(),
  android: LiveAndroid(
    title: bind('titulo'),
    text: const LiveText.format('{subtitulo} · {nombre}'),
    chip: LiveChip.countdown(bind('llegaA')),
  ),
);
