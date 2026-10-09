// Los ejemplos del README, compilados aquí para que no se desfasen de la API.
// Se analizan con `flutter analyze`; no se ejecutan.
import 'dart:ui' show Color;

import 'package:live_island/live_island.dart';

/// Nivel 1: un preset tal cual.
Future<void> nivel1() async {
  final actividad = await LiveIsland.start(
    layout: const ParkingPreset().build(),
    state: {
      'titulo': 'Estacionamiento activo',
      'subtitulo': 'Zona azul · Av. Larco 400',
      'nombre': 'Placa ABC-123',
      'llegaA': DateTime.now().add(const Duration(minutes: 45)),
      'progreso': 0.0,
    },
  );

  await actividad.update({'progreso': 0.5}); // solo viaja lo que cambia
  await actividad.end(dismiss: const LiveDismiss.after(Duration(minutes: 5)));
}

/// Nivel 2: un preset con sus parámetros y `.override` en una región.
LiveLayout nivel2() => const TripPreset(
  accent: Color(0xFFD81B60),
  stages: ['Pedido', 'En camino', 'Llegó'],
).override(
  // La isla compacta muestra la placa en lugar de la cuenta regresiva.
  compactTrailing: LiveText.from(
    const LiveText(LiveBind('placa')),
    size: 15,
    weight: 600,
    accent: true,
  ),
);

/// Nivel 3: un diseño desde cero, con los componentes.
LiveLayout nivel3() => LiveLayout(
  theme: const LiveTheme(accent: Color(0xFF00897B)),
  compactLeading: const LiveIcon.symbol('timer', accent: true),
  compactTrailing: LiveText.from(
    LiveText.countdown(bind('termina')),
    size: 15,
    weight: 600,
    accent: true,
  ),
  minimal: const LiveIcon.symbol('timer', accent: true),
  expanded: LiveExpanded(
    leading: const LiveBox(
      child: LiveIcon.symbol('timer', accent: true),
      size: 46,
      radius: 14,
      tint: 0.22,
    ),
    center: const LiveColumn([
      LiveText(LiveBind('titulo'), size: 15, weight: 600),
      LiveText(LiveBind('detalle'), size: 13, muted: true),
    ]),
    trailing: LiveText.from(
      LiveText.countdown(bind('termina')),
      size: 22,
      weight: 700,
      accent: true,
    ),
    bottom: LiveProgress.bar(value: bind('progreso')),
  ),
  lockScreen: const LiveLockScreen.sameAsExpanded(),
  android: LiveAndroid(
    title: bind('titulo'),
    text: const LiveText.format('{detalle}'),
    chip: LiveChip.countdown(bind('termina')),
  ),
);

/// Botones, vista previa y validación.
Future<void> extras() async {
  // Cada botón de la actividad llega aquí con su id.
  LiveIsland.onAction((id) {
    if (id == 'mas_15_min') {
      // ... amplía el tiempo y actualiza la actividad
    }
  });

  // Antes de compilar la extensión, comprueba el diseño.
  final preset = const TripPreset();
  final informe = LiveIsland.check(preset.build(), preset.sampleState());
  if (informe.hasErrors) {
    // ignore: avoid_print
    print(informe);
  }

  // Los diseños con nombre permiten iniciar actividades desde un push.
  await LiveIsland.registerLayout('taxi', preset.build());
}
