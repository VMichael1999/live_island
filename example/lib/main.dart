import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:live_island/live_island.dart';

import 'demos.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'live_island',
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1F6FEB),
    ),
    home: const DemoScreen(),
  );
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  Demo _demo = demos.first;
  late Map<String, Object?> _state = _demo.state();
  LiveActivity? _activity;
  String _status = 'Sin actividad';

  @override
  void initState() {
    super.initState();
    // Solo en debug: `SIMCTL_CHILD_LIVE_ISLAND_AUTOSTART=taxi xcrun simctl launch …`
    // inicia el caso sin tocar la pantalla (útil para capturas).
    final auto =
        kDebugMode ? Platform.environment['LIVE_ISLAND_AUTOSTART'] : null;
    if (auto != null) {
      _demo = demos.firstWhere((d) => d.id == auto, orElse: () => demos.first);
      _state = _demo.state();
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _pick(Demo d) => setState(() {
    _demo = d;
    _state = d.state();
  });

  Future<void> _run(String what, Future<void> Function() body) async {
    try {
      await body();
    } on LiveIslandException catch (e) {
      setState(() => _status = '$what falló: ${e.code}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _start() => _run('Iniciar', () async {
    // Android 13+: pide el permiso de notificaciones (en iOS no hace nada).
    await LiveIsland.requestPermission();
    _state = _demo.state();
    final a = await LiveIsland.start(
      layout: _demo.layout,
      state: _state,
      deepLink: 'liveisland://${_demo.id}',
    );
    setState(() {
      _activity = a;
      _status = 'Activa (${a.id.substring(0, 8)}…)';
    });
  });

  Future<void> _advance() => _run('Actualizar', () async {
    final next = ((_state['progreso'] as num) + 0.1).clamp(0.0, 1.0).toDouble();
    await _activity!.update({'progreso': next});
    setState(() {
      _state = {..._state, 'progreso': next};
      _status = 'Progreso ${(next * 100).round()} %';
    });
  });

  Future<void> _end() => _run('Terminar', () async {
    await _activity!.end(dismiss: LiveDismiss.immediate);
    setState(() {
      _activity = null;
      _status = 'Sin actividad';
    });
  });

  @override
  Widget build(BuildContext context) {
    final report = LiveIsland.check(_demo.layout, _state);
    return Scaffold(
      appBar: AppBar(title: const Text('live_island')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final d in demos)
                ChoiceChip(
                  label: Text(d.label),
                  selected: d == _demo,
                  onSelected: (_) => _pick(d),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(onPressed: _start, child: const Text('Iniciar')),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _activity == null ? null : _advance,
                child: const Text('Avanzar 10 %'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _activity == null ? null : _end,
                child: const Text('Terminar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_status),
          const SizedBox(height: 16),
          LiveIslandPreview(
            layout: _demo.layout,
            state: _state,
            appName: _demo.app,
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
      ),
    );
  }
}
