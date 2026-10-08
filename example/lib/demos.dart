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
    'courier',
    'Courier',
    'Envíos Rápidos',
    _courier(),
    () => {
      'titulo': 'Tu paquete llega hoy',
      'subtitulo': 'Quedan 3 paradas antes de la tuya',
      'nombre': 'Ruta 14',
      'destacado': '3 paradas',
      'progreso': 0.4,
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
  // Android pinta el ícono pequeño como silueta de un color.
  androidSmallIcon: LiveImage.asset('assets/live/logo_silueta.png'),
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
        endIcon: const LiveIcon.symbol(
          'mappin',
          android: 'assets/live/mappin.png',
        ),
      ),
      LiveRow([
        LiveButton(
          id: 'llamar',
          label: 'Llamar',
          icon: const LiveIcon.symbol(
            'phone.fill',
            android: 'assets/live/phone.png',
          ),
        ),
        LiveButton(
          id: 'compartir',
          label: 'Compartir',
          icon: const LiveIcon.symbol(
            'square.and.arrow.up',
            android: 'assets/live/share2.png',
          ),
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
  appLogo: const LiveIcon.symbol(
    'fork.knife',
    android: 'assets/live/utensils.png',
  ),
  compactLeading: const LiveIcon.symbol(
    'fork.knife',
    android: 'assets/live/utensils.png',
    accent: true,
  ),
  compactTrailing: _compactHighlight(),
  minimal: const LiveIcon.symbol(
    'fork.knife',
    android: 'assets/live/utensils.png',
    accent: true,
  ),
  expanded: LiveExpanded(
    leading: const LiveBox(
      child: LiveIcon.symbol(
        'fork.knife',
        android: 'assets/live/utensils.png',
        accent: true,
      ),
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
        tracker: const LiveIcon.symbol(
          'bicycle',
          android: 'assets/live/bike.png',
        ),
        endIcon: const LiveIcon.symbol(
          'house.fill',
          android: 'assets/live/house.png',
        ),
      ),
      LiveRow([
        LiveButton(
          id: 'llamar',
          label: 'Llamar',
          icon: const LiveIcon.symbol(
            'phone.fill',
            android: 'assets/live/phone.png',
          ),
        ),
        LiveButton(
          id: 'ver_mapa',
          label: 'Ver mapa',
          icon: const LiveIcon.symbol(
            'mappin',
            android: 'assets/live/mappin.png',
          ),
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
  appLogo: const LiveIcon.symbol(
    'parkingsign.circle.fill',
    android: 'assets/live/squareparking.png',
  ),
  compactLeading: const LiveIcon.symbol(
    'parkingsign.circle.fill',
    accent: true,
  ),
  compactTrailing: _compactHighlight(),
  minimal: LiveProgress.ring(
    value: bind('progreso'),
    child: const LiveIcon.symbol(
      'parkingsign.circle.fill',
      android: 'assets/live/squareparking.png',
      accent: true,
    ),
  ),
  expanded: LiveExpanded(
    leading: const LiveBox(
      child: LiveIcon.symbol(
        'parkingsign.circle.fill',
        android: 'assets/live/squareparking.png',
        accent: true,
      ),
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
          icon: const LiveIcon.symbol('plus', android: 'assets/live/plus.png'),
        ),
        LiveButton(
          id: 'terminar',
          label: 'Terminar',
          icon: const LiveIcon.symbol('xmark', android: 'assets/live/x.png'),
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

LiveLayout _courier() => LiveLayout(
  theme: const LiveTheme(accent: Color(0xFF6D4C41)),
  appLogo: const LiveIcon.symbol(
    'shippingbox.fill',
    android: 'assets/live/package.png',
  ),
  compactLeading: const LiveIcon.symbol(
    'shippingbox.fill',
    android: 'assets/live/package.png',
    accent: true,
  ),
  compactTrailing: LiveText.from(
    LiveText(bind('destacado')),
    size: 15,
    weight: 600,
    accent: true,
  ),
  minimal: const LiveIcon.symbol(
    'shippingbox.fill',
    android: 'assets/live/package.png',
    accent: true,
  ),
  expanded: LiveExpanded(
    leading: const LiveBox(
      child: LiveIcon.symbol(
        'shippingbox.fill',
        android: 'assets/live/package.png',
        accent: true,
      ),
      size: 46,
      radius: 14,
      tint: 0.22,
    ),
    center: _centerText(),
    trailing: LiveColumn([
      LiveText.from(
        LiveText(bind('destacado')),
        size: 22,
        weight: 700,
        accent: true,
      ),
      LiveText(bind('nombre'), size: 12, muted: true),
    ], align: LiveAlign.end),
    bottom: LiveColumn([
      LiveSegments(
        value: bind('progreso'),
        labels: const ['Almacén', 'En ruta', 'Cerca', 'Entregado'],
        points: true,
        tracker: const LiveIcon.symbol(
          'truck.box.fill',
          android: 'assets/live/truck.png',
        ),
        endIcon: const LiveIcon.symbol(
          'house.fill',
          android: 'assets/live/house.png',
        ),
      ),
      LiveRow([
        LiveButton(
          id: 'ver_ruta',
          label: 'Ver ruta',
          icon: const LiveIcon.symbol(
            'mappin',
            android: 'assets/live/mappin.png',
          ),
        ),
      ]),
    ], gap: 12),
  ),
  lockScreen: const LiveLockScreen.sameAsExpanded(),
  android: LiveAndroid(
    title: bind('titulo'),
    text: const LiveText.format('{subtitulo} · {nombre}'),
    chip: const LiveChip.text('3 más'),
  ),
);
