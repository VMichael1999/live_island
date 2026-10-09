import 'package:flutter/material.dart';
import 'package:live_island/live_island.dart';

import 'catalog.dart';
import 'main.dart';

/// Un preset: vista previa, iniciar / avanzar / terminar, push y validación.
class PresetScreen extends StatefulWidget {
  const PresetScreen(this.entry, {super.key});

  final CatalogEntry entry;

  @override
  State<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends State<PresetScreen> {
  late final preset = widget.entry.preset;
  late final layout = preset.build();
  late Map<String, Object?> sample = preset.sampleState();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.entry.label)),
    body: ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final mine =
            model.activeEntry == widget.entry && model.activity != null;
        final state = mine ? model.state : sample;
        final report = LiveIsland.check(
          layout,
          state,
          androidPromotable: preset.androidPromotable,
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () {
                    sample = preset.sampleState();
                    model.start(widget.entry, layout, sample);
                  },
                  child: const Text('Iniciar'),
                ),
                OutlinedButton(
                  onPressed: model.activity == null ? null : model.advance,
                  child: const Text('Avanzar 10 %'),
                ),
                OutlinedButton(
                  onPressed: model.activity == null ? null : model.end,
                  child: const Text('Terminar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(model.status),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed:
                      () => model.simulatePush({
                        'event': 'start',
                        'template': widget.entry.id,
                        'state': {
                          for (final e in preset.sampleState().entries)
                            e.key:
                                e.value is DateTime
                                    ? (e.value! as DateTime)
                                        .toUtc()
                                        .toIso8601String()
                                    : e.value,
                        },
                      }),
                  child: const Text('Push: iniciar'),
                ),
                OutlinedButton(
                  onPressed:
                      model.activity == null
                          ? null
                          : () => model.simulatePush({
                            'event': 'update',
                            'id': model.activity!.id,
                            'state': {'progreso': 0.9},
                          }),
                  child: const Text('Push: progreso 90 %'),
                ),
                OutlinedButton(
                  onPressed:
                      model.activity == null
                          ? null
                          : () => model.simulatePush({
                            'event': 'end',
                            'id': model.activity!.id,
                            'dismiss': 'immediate',
                          }),
                  child: const Text('Push: terminar'),
                ),
              ],
            ),
            for (final t in model.tokens)
              Text(t, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            LiveIslandPreview(
              layout: layout,
              state: state,
              appName: preset.appName,
              androidPromotable: preset.androidPromotable,
            ),
            const SizedBox(height: 24),
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
        );
      },
    ),
  );
}
