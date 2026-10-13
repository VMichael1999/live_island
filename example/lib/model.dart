import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:live_island/live_island.dart';

import 'catalog.dart';

/// Estado compartido de la app de ejemplo: la actividad en curso, los botones
/// que llegan, los tokens de push y los mensajes de estado.
class ExampleModel extends ChangeNotifier {
  LiveActivity? activity;
  CatalogEntry? activeEntry;
  Map<String, Object?> state = const {};
  String status = 'Sin actividad';
  final List<String> tokens = [];
  final List<StreamSubscription<Object?>> _subs = [];

  /// Inicia el modelo: escucha botones, tokens y push, y registra los diseños.
  void init() {
    // Un botón de la actividad (pantalla de bloqueo o notificación) llega aquí,
    // también si la app estaba cerrada.
    _subs.add(LiveIsland.onAction(_onAction));
    // Tokens de push de iOS (para enviarlos a tu servidor).
    _subs.add(
      LiveIsland.pushTokens.listen((t) {
        tokens.add('$t');
        notifyListeners();
      }),
    );
    // Actividades iniciadas por un push.
    _subs.add(
      LiveIsland.startedByPush.listen((a) {
        activity = a;
        status = 'Iniciada por push (${a.id.substring(0, 8)}…)';
        notifyListeners();
      }),
    );
    // Recupera la actividad que siguió viva tras cerrar la app.
    LiveIsland.activeActivities().then((list) {
      if (list.isNotEmpty && activity == null) {
        activity = list.last;
        status =
            'Recuperada (${list.last.customId ?? list.last.id.substring(0, 8)})';
        notifyListeners();
      }
    });
    // Los diseños con nombre permiten iniciar actividades desde un push.
    for (final e in catalog) {
      LiveIsland.registerLayout(e.id, e.preset.build()).catchError((_) {});
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _setStatus(String s) {
    status = s;
    notifyListeners();
  }

  Future<void> _guard(String what, Future<void> Function() body) async {
    try {
      await body();
    } on LiveIslandException catch (e) {
      _setStatus('$what falló: ${e.code} · ${e.message}');
    }
  }

  /// En la demo solo hay una actividad a la vez.
  ///
  /// iOS muestra **una sola** actividad en la isla (la de mayor `relevance`;
  /// con el mismo valor, la más antigua). Si otro caso de la lista siguiera
  /// vivo, al iniciar uno nuevo la isla seguiría mostrando el anterior. Aquí
  /// se terminan las demás; una app real decide su propia política (o usa
  /// `relevance` para ordenarlas).
  Future<void> _endOthers(String keepCustomId) async {
    for (final a in await LiveIsland.activeActivities()) {
      if (a.customId != keepCustomId) {
        await a.end(dismiss: LiveDismiss.immediate);
      }
    }
  }

  /// Inicia [layout] con [newState].
  Future<void> start(
    CatalogEntry entry,
    LiveLayout layout,
    Map<String, Object?> newState,
  ) => _guard('Iniciar', () async {
    // Android 13+: pide el permiso de notificaciones (en iOS no hace nada).
    await LiveIsland.requestPermission();
    await _endOthers('demo-${entry.id}');
    final a = await LiveIsland.start(
      layout: layout,
      state: newState,
      deepLink: 'liveisland://${entry.id}',
      // Iniciar el mismo caso otra vez actualiza la actividad en vez de crear otra.
      customId: 'demo-${entry.id}',
      // La que se acaba de iniciar es la que debe verse en la isla.
      relevance: 100,
    );
    activity = a;
    activeEntry = entry;
    state = newState;
    _setStatus('Activa (${a.id.substring(0, 8)}…)');
  });

  /// Una actividad que se «desactualiza» sola: pasados [seconds] s el sistema
  /// la vuelve a dibujar con `LiveBind.stale` en `true` (iOS 16.2 o superior).
  Future<void> startStale(
    CatalogEntry entry,
    LiveLayout layout,
    Map<String, Object?> newState, {
    int seconds = 15,
  }) => _guard('Iniciar (desactualizable)', () async {
    await LiveIsland.requestPermission();
    await _endOthers('demo-stale-${entry.id}');
    final stale = entry.preset.override(
      expandedCenter: LiveIf(
        LiveBind.stale.isTrue,
        then: const LiveText.literal(
          'Sin novedades: toca para actualizar',
          size: 15,
          weight: 600,
        ),
        otherwise: LiveText(bind('titulo'), size: 15, weight: 600),
      ),
    );
    final a = await LiveIsland.start(
      layout: stale,
      state: newState,
      staleAfter: Duration(seconds: seconds),
      customId: 'demo-stale-${entry.id}',
      relevance: 100,
    );
    activity = a;
    activeEntry = entry;
    state = newState;
    _setStatus('Se desactualiza en $seconds s');
  });

  /// Programa que la actividad desaparezca sola dentro de [seconds] s.
  ///
  /// Android: sigue viva y se puede actualizar hasta entonces. iOS: termina ya y
  /// la tarjeta de la pantalla de bloqueo se queda hasta esa hora.
  Future<void> scheduleEnd({int seconds = 20}) =>
      _guard('Programar fin', () async {
        final a = activity ?? (await LiveIsland.activeActivities()).lastOrNull;
        if (a == null) return;
        await a.scheduleEnd(DateTime.now().add(Duration(seconds: seconds)));
        _setStatus('Desaparece en $seconds s');
      });

  /// Actualiza con un aviso: la isla se expande y suena.
  Future<void> alert() => _guard('Avisar', () async {
    final a = activity ?? (await LiveIsland.activeActivities()).lastOrNull;
    if (a == null) return;
    await a.update(
      {'progreso': (((state['progreso'] as num?) ?? 0) + 0.1).clamp(0.0, 1.0)},
      alert: const LiveAlert(
        title: 'Tu conductor llegó',
        body: 'Toyota Yaris gris · ABC-123',
      ),
    );
    state = {
      ...state,
      'progreso': (((state['progreso'] as num?) ?? 0) + 0.1).clamp(0.0, 1.0),
    };
    _setStatus('Aviso enviado');
  });

  Future<void> update(Map<String, Object?> changes, {String? label}) =>
      _guard('Actualizar', () async {
        final a = activity ?? (await LiveIsland.activeActivities()).lastOrNull;
        if (a == null) return;
        activity = a;
        await a.update(changes);
        state = {...state, ...changes};
        _setStatus(label ?? 'Actualizada: ${changes.keys.join(', ')}');
      });

  Future<void> advance() {
    final next =
        ((((state['progreso'] as num?) ?? 0) + 0.1).clamp(0.0, 1.0)).toDouble();
    return update({
      'progreso': next,
    }, label: 'Progreso ${(next * 100).round()} %');
  }

  /// Termina todas las actividades de la app (por ejemplo al cerrar sesión).
  Future<void> endAll() => _guard('Terminar todas', () async {
    await LiveIsland.endAll();
    activity = null;
    _setStatus('Todas terminadas');
  });

  Future<void> end() => _guard('Terminar', () async {
    await activity?.end(dismiss: LiveDismiss.immediate);
    activity = null;
    _setStatus('Sin actividad');
  });

  /// Qué hace cada botón de los ejemplos. El id es el de `LiveButton(id: ...)`.
  Future<void> _onAction(String id) async {
    if (id == 'terminar') return end();
    final changes = switch (id) {
      'mas_15_min' => <String, Object?>{
        'llegaA': DateTime.now().add(const Duration(minutes: 60)),
      },
      'llamar' => <String, Object?>{
        'progreso':
            ((((state['progreso'] as num?) ?? 0) + 0.1).clamp(
              0.0,
              1.0,
            )).toDouble(),
      },
      _ => <String, Object?>{'subtitulo': 'Tocaste "$id"'},
    };
    await update(changes, label: 'Botón "$id" → ${changes.keys.join(', ')}');
  }

  /// Simula un mensaje de FCM (Android): lo que haría tu servidor.
  Future<void> simulatePush(Map<String, Object?> payload) =>
      _guard('Push', () async {
        final id = await LiveIsland.handlePush({
          'live_island': jsonEncode(payload),
        });
        if (id != null) _setStatus('Push aplicado a ${id.substring(0, 8)}…');
      });
}
