// The README examples, compiled here so they never drift from the API.
// They are checked by `flutter analyze`; they are not run.
import 'dart:ui' show Color;

import 'package:live_island_kit/live_island_kit.dart';

/// Level 1: a preset as it is.
Future<void> nivel1() async {
  final activity = await LiveIsland.start(
    layout: const ParkingPreset().build(),
    state: {
      'titulo': 'Parking active',
      'subtitulo': 'Blue zone · Av. Larco 400',
      'nombre': 'Plate ABC-123',
      'llegaA': DateTime.now().add(const Duration(minutes: 45)),
      'progreso': 0.0,
    },
  );

  await activity.update({'progreso': 0.5}); // only what changes travels
  await activity.end(dismiss: const LiveDismiss.after(Duration(minutes: 5)));
}

/// Level 2: a preset with its parameters and `.override` on one region.
LiveLayout nivel2() => const TripPreset(
  accent: Color(0xFFD81B60),
  stages: ['Order', 'On the way', 'Arrived'],
).override(
  // The compact island shows the plate instead of the countdown.
  compactTrailing: LiveText.from(
    const LiveText(LiveBind('placa')),
    size: 15,
    weight: 600,
    accent: true,
  ),
);

/// Level 3: a design from scratch, with the components.
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

/// Buttons, preview and validation.
Future<void> extras() async {
  // Each button of the activity arrives here with its id.
  LiveIsland.onAction((id) {
    if (id == 'mas_15_min') {
      // ... extend the time and update the activity
    }
  });

  // Before building the extension, check the design.
  final preset = const TripPreset();
  final report = LiveIsland.check(preset.build(), preset.sampleState());
  if (report.hasErrors) {
    // ignore: avoid_print
    print(report);
  }

  // Named layouts let a push start activities.
  await LiveIsland.registerLayout('taxi', preset.build());
}
