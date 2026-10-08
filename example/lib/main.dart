import 'package:flutter/material.dart';
import 'package:live_island/live_island.dart';

void main() => runApp(const ExampleApp());

/// Diseño de ejemplo: un viaje en taxi con cuenta regresiva y etapas.
LiveLayout taxiLayout() => LiveLayout(
  theme: const LiveTheme(accent: Color(0xFF1F6FEB)),
  appLogo: const LiveIcon.symbol('car.fill', android: 'assets/live/car.png'),
  compactLeading: const LiveAvatar('CM'),
  compactTrailing: LiveText.countdown(bind('llegaA')),
  minimal: const LiveAvatar('CM'),
  expanded: LiveExpanded(
    leading: const LiveAvatar('CM', size: 46),
    center: LiveColumn([
      LiveText(bind('titulo'), weight: 600),
      LiveText(bind('subtitulo'), muted: true),
    ]),
    trailing: LiveColumn([
      LiveText.from(
        LiveText.countdown(bind('llegaA')),
        size: 22,
        weight: 700,
        accent: true,
      ),
      LiveText(bind('nombre'), muted: true),
    ], align: LiveAlign.end),
    bottom: LiveColumn([
      LiveSegments(
        value: bind('progreso'),
        labels: const ['Asignado', 'En camino', 'Llegó'],
        points: true,
        tracker: const LiveIcon.symbol('car.fill'),
        endIcon: const LiveIcon.symbol('mappin'),
      ),
      LiveRow([LiveButton(id: 'llamar', label: 'Llamar')]),
    ]),
  ),
  lockScreen: const LiveLockScreen.sameAsExpanded(),
  android: LiveAndroid(
    title: bind('titulo'),
    text: const LiveText.format('{subtitulo} · {nombre}'),
    chip: LiveChip.countdown(bind('llegaA')),
  ),
);

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = {
      'titulo': 'Tu conductor está en camino',
      'subtitulo': 'Toyota Yaris gris · ABC-123',
      'nombre': 'Carlos M.',
      'llegaA': DateTime.now().add(const Duration(minutes: 6)),
      'progreso': 0.45,
    };
    final report = LiveIsland.check(taxiLayout(), state);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('live_island')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Validación', style: Theme.of(context).textTheme.titleMedium),
            for (final c in report.items)
              ListTile(
                dense: true,
                leading: Icon(switch (c.severity) {
                  LiveSeverity.ok => Icons.check_circle_outline,
                  LiveSeverity.warn => Icons.warning_amber,
                  LiveSeverity.bad => Icons.error_outline,
                }),
                title: Text(c.message),
              ),
          ],
        ),
      ),
    );
  }
}
