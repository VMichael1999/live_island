import 'dart:async';
import 'dart:convert';

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

  final List<StreamSubscription<Object?>> _subs = [];
  final List<String> _tokens = [];

  @override
  void initState() {
    super.initState();
    // Un botón de la actividad (pantalla de bloqueo o notificación) llega aquí,
    // también si la app estaba cerrada.
    _subs.add(LiveIsland.onAction(_onAction));
    // Tokens de push de iOS (para enviarlos a tu servidor).
    _subs.add(
      LiveIsland.pushTokens.listen((t) {
        if (mounted) setState(() => _tokens.add('$t'));
      }),
    );
    // Actividades iniciadas por un push.
    _subs.add(
      LiveIsland.startedByPush.listen((a) {
        if (mounted) {
          setState(() {
            _activity = a;
            _status = 'Iniciada por push (${a.id.substring(0, 8)}…)';
          });
        }
      }),
    );
    // Recupera la actividad que siguió viva tras cerrar la app.
    LiveIsland.activeActivities().then((list) {
      if (mounted && list.isNotEmpty && _activity == null) {
        setState(() {
          _activity = list.last;
          _status = 'Recuperada (${list.last.id.substring(0, 8)}…)';
        });
      }
    });
    // Los diseños con nombre permiten iniciar actividades desde un push.
    for (final d in demos) {
      LiveIsland.registerLayout(d.id, d.layout).catchError((_) {});
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  /// Qué hace cada botón de los ejemplos. El id es el de `LiveButton(id: ...)`.
  Future<void> _onAction(String id) async {
    // Con la app cerrada la actividad sigue viva: se recupera antes de actuar.
    final a = _activity ?? (await LiveIsland.activeActivities()).lastOrNull;
    if (a == null) return;
    _activity = a;
    final cambios = switch (id) {
      'mas_15_min' => <String, Object?>{
        'llegaA': DateTime.now().add(const Duration(minutes: 60)),
      },
      'llamar' => <String, Object?>{
        'progreso': (((_state['progreso'] as num?) ?? 0) + 0.1).clamp(0.0, 1.0),
      },
      _ => <String, Object?>{'subtitulo': 'Tocaste "$id"'},
    };
    if (id == 'terminar') {
      await a.end(dismiss: LiveDismiss.immediate);
      if (mounted) {
        setState(() {
          _activity = null;
          _status = 'Terminada desde un botón';
        });
      }
      return;
    }
    await a.update(cambios);
    if (mounted) {
      setState(() {
        _state = {..._state, ...cambios};
        _status = 'Botón "$id" → ${cambios.keys.join(', ')}';
      });
    }
  }

  /// Simula un mensaje de FCM (Android): lo que haría tu servidor.
  Future<void> _simulatePush(Map<String, Object?> payload) =>
      _run('Push', () async {
        final id = await LiveIsland.handlePush({
          'live_island': jsonEncode(payload),
        });
        if (mounted && id != null) {
          setState(() => _status = 'Push aplicado a ${id.substring(0, 8)}…');
        }
      });

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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed:
                    () => _simulatePush({
                      'event': 'start',
                      'template': _demo.id,
                      'state': {
                        for (final e in _demo.state().entries)
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
                    _activity == null
                        ? null
                        : () => _simulatePush({
                          'event': 'update',
                          'id': _activity!.id,
                          'state': {'progreso': 0.9},
                        }),
                child: const Text('Push: progreso 90 %'),
              ),
              OutlinedButton(
                onPressed:
                    _activity == null
                        ? null
                        : () => _simulatePush({
                          'event': 'end',
                          'id': _activity!.id,
                          'dismiss': 'immediate',
                        }),
                child: const Text('Push: terminar'),
              ),
            ],
          ),
          for (final t in _tokens)
            Text(t, style: Theme.of(context).textTheme.bodySmall),
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
