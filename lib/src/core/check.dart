import 'dart:convert';
import 'dart:math' as math;

import '../components/progress.dart';
import '../components/text.dart';
import '../components/visuals.dart';
import 'bind.dart';
import 'enums.dart';
import 'layout.dart';
import 'node.dart';
import 'state.dart';

/// Límite de 4 096 bytes escrito como en el HTML de prototipos.
const _maxBytesLabel = '4 096';

/// Gravedad de un aviso de [LiveIsland.check].
enum LiveSeverity { ok, warn, bad }

/// Un aviso del informe de validación.
class LiveCheck {
  const LiveCheck(this.severity, this.code, this.message);

  final LiveSeverity severity;

  /// Identificador estable para pruebas y filtros.
  final String code;
  final String message;

  @override
  String toString() => '[${severity.name}] $message';
}

/// Resultado de validar un diseño con su estado.
class LiveReport {
  const LiveReport(this.items);

  final List<LiveCheck> items;

  bool get hasErrors => items.any((c) => c.severity == LiveSeverity.bad);
  bool get hasWarnings => items.any((c) => c.severity == LiveSeverity.warn);

  /// Primer aviso con el [code] dado, si existe.
  LiveCheck? byCode(String code) {
    for (final c in items) {
      if (c.code == code) return c;
    }
    return null;
  }

  @override
  String toString() => items.join('\n');
}

/// Valida [layout] con [state] con el mismo criterio del panel "Validación"
/// del HTML de prototipos.
///
/// [now] fija el instante usado para las cuentas regresivas.
/// [androidPromotable] es `false` para casos que Google no promueve a Live
/// Update (publicidad, chats, actividades que no inició el usuario).
LiveReport checkLayout(
  LiveLayout layout,
  Map<String, Object?> state, {
  DateTime? now,
  bool androidPromotable = true,
}) {
  final clock = (now ?? DateTime.now()).toUtc();
  final data = LiveState.normalize(state);
  final rows = <LiveCheck>[];

  // 1. Peso del estado.
  final bytes = utf8.encode(jsonEncode(data)).length;
  final payload =
      'Estado por actualización: $bytes bytes de $_maxBytesLabel '
      '(iOS). Solo viajan datos, el diseño se envía una vez.';
  if (bytes > LiveState.maxBytes) {
    rows.add(
      LiveCheck(
        LiveSeverity.bad,
        'statePayload',
        'El estado pesa $bytes bytes y supera los $_maxBytesLabel de iOS. '
            'Quita campos o acorta los textos.',
      ),
    );
  } else {
    rows.add(LiveCheck(LiveSeverity.ok, 'statePayload', payload));
  }

  // 2. Dato destacado en la isla compacta.
  final highlight = _text(layout.compactTrailing, data, clock);
  if (highlight != null) {
    final n = highlight.runes.length;
    rows.add(
      n > 7
          ? LiveCheck(
            LiveSeverity.warn,
            'highlightLength',
            'El dato destacado tiene $n caracteres; en la isla compacta se recorta. Usa 7 o menos.',
          )
          : const LiveCheck(
            LiveSeverity.ok,
            'highlightLength',
            'El dato destacado cabe en la isla compacta.',
          ),
    );
  }

  // 3. Chip de Android.
  final android = layout.android;
  final chip = _chip(android?.chip, data, clock);
  if (chip != null) {
    final len = chip.length;
    if (chip.mode == _ChipMode.full) {
      rows.add(
        LiveCheck(
          LiveSeverity.ok,
          'chip',
          'Chip de Android completo ($len caracteres).',
        ),
      );
    } else if (chip.mode == _ChipMode.cut) {
      rows.add(
        LiveCheck(
          LiveSeverity.warn,
          'chip',
          'Chip de Android recortado: “${chip.text}” tiene $len caracteres (máximo 7 para verse completo).',
        ),
      );
    } else {
      rows.add(
        LiveCheck(
          LiveSeverity.warn,
          'chip',
          'Chip de Android solo con ícono${chip.text.isNotEmpty ? ': el texto es demasiado largo.' : '.'}',
        ),
      );
    }
  }

  // 4. ¿Android lo promueve?
  final title = _androidText(android?.title, data);
  if (!androidPromotable) {
    rows.add(
      const LiveCheck(
        LiveSeverity.bad,
        'androidPromotion',
        'Android no promueve este caso: no lo inició el usuario como actividad con inicio y fin. Se muestra como notificación normal.',
      ),
    );
  } else if (android?.colorized ?? false) {
    rows.add(
      const LiveCheck(
        LiveSeverity.bad,
        'androidPromotion',
        'Android no promueve notificaciones con setColorized(true). Quita el color de fondo.',
      ),
    );
  } else if (title == null || title.isEmpty) {
    rows.add(
      const LiveCheck(
        LiveSeverity.bad,
        'androidPromotion',
        'Android exige un título (setContentTitle) para promover.',
      ),
    );
  } else {
    rows.add(
      const LiveCheck(
        LiveSeverity.ok,
        'androidPromotion',
        'Android la promueve a Live Update (estilo nativo, sin RemoteViews).',
      ),
    );
  }

  // 5. Anillo en Android. Se evalúa el progreso que usará Android.
  final androidProgress =
      android?.progress ?? firstProgress(layout.expanded?.bottom);
  if (androidProgress is LiveProgress && androidProgress.isRing) {
    rows.add(
      const LiveCheck(
        LiveSeverity.warn,
        'ringOnAndroid',
        'El anillo no existe en Android: se muestra como barra de ProgressStyle.',
      ),
    );
  }

  // 6. Etapas insuficientes.
  for (final n in layout.allNodes) {
    if (n is LiveSegments && n.labels.length < 2) {
      rows.add(
        const LiveCheck(
          LiveSeverity.warn,
          'segmentsFewStages',
          'Para la barra por etapas escribe al menos dos etapas.',
        ),
      );
      break;
    }
  }

  // 7. Ícono pequeño de Android.
  if (layout.appLogo is LiveImage && layout.androidSmallIcon == null) {
    rows.add(
      const LiveCheck(
        LiveSeverity.warn,
        'androidSmallIcon',
        'En Android el ícono pequeño (barra de estado, chip y encabezado) se ve como silueta de un solo color. El logo a color se muestra como ícono grande; conviene darle una versión en silueta con androidSmallIcon.',
      ),
    );
  }

  // 8. Peso de las imágenes y a qué tamaño se reducen.
  for (final slot in _imageSlots(layout)) {
    final img = slot.image;
    final kb =
        img.byteSize == null
            ? ''
            : '${math.max(1, (img.byteSize! / 1024).round())} KB, ';
    rows.add(
      LiveCheck(
        LiveSeverity.ok,
        'imageSize',
        '${slot.label}: ${kb}se reduce a ${slot.px} antes de copiarse al App Group (iOS). '
            'Proporción respetada con fit “${img.fit.name}”.',
      ),
    );
  }

  return LiveReport(rows);
}

class _Slot {
  const _Slot(this.label, this.px, this.image);
  final String label, px;
  final LiveImage image;
}

/// Las cuatro ranuras de imagen del editor del HTML, en su mismo orden.
List<_Slot> _imageSlots(LiveLayout layout) {
  final slots = <_Slot>[];
  final logo = layout.appLogo;
  if (logo is LiveImage) {
    slots.add(_Slot('Logo de la app', '120 × 120 px', logo));
  }
  LiveImage? main, avatar;
  final leads = [
    layout.compactLeading,
    layout.minimal,
    layout.expanded?.leading,
  ];
  for (final root in leads) {
    if (root == null) continue;
    for (final n in root.descendants) {
      if (n is LiveAvatar && n.photo != null) {
        avatar ??= n.photo;
      } else if (n is LiveImage) {
        if (n.shape == LiveShape.circle) {
          avatar ??= n;
        } else {
          main ??= n;
        }
      }
    }
  }
  if (main != null) {
    slots.add(_Slot('Imagen del ícono principal', '138 × 138 px', main));
  }
  if (avatar != null) {
    slots.add(_Slot('Foto del avatar', '138 × 138 px', avatar));
  }
  final progress = _firstProgressAnywhere(layout);
  final tracker = switch (progress) {
    LiveProgress p => p.tracker,
    LiveSegments s => s.tracker,
    _ => null,
  };
  if (tracker?.visual is LiveImage) {
    slots.add(
      _Slot(
        'Imagen que avanza en la barra',
        '72 px de alto',
        tracker!.visual as LiveImage,
      ),
    );
  }
  return slots;
}

LiveNode? _firstProgressAnywhere(LiveLayout layout) {
  for (final n in layout.allNodes) {
    if (n is LiveProgress || n is LiveSegments) return n;
  }
  return null;
}

enum _ChipMode { full, cut, icon }

/// Mismo criterio que `chipInfo` del HTML.
({String text, _ChipMode mode, int length})? _chip(
  LiveChip? chip,
  Map<String, Object?> data,
  DateTime now,
) {
  if (chip == null) return null;
  var text = switch (chip.type) {
    'countdown' => '${_remainingMinutes(data[chip.bind!.field], now)} min',
    'text' => chip.text ?? '',
    _ => '',
  };
  final len = text.runes.length;
  if (text.isEmpty || len > 12) {
    return (text: text, mode: _ChipMode.icon, length: len);
  }
  if (len > 7) {
    return (text: text, mode: _ChipMode.cut, length: len);
  }
  return (text: text, mode: _ChipMode.full, length: len);
}

int _remainingMinutes(Object? date, DateTime now) {
  final s = _remainingSeconds(date, now);
  final m = (s / 60).ceil();
  return m < 1 ? 1 : m;
}

int _remainingSeconds(Object? date, DateTime now) {
  final dl = date is String ? DateTime.tryParse(date) : null;
  if (dl == null) return 0;
  final ms = dl.difference(now).inMilliseconds;
  // Igual que Math.round de JavaScript: la mitad sube.
  final s = (ms / 1000 + 0.5).floor();
  return s < 0 ? 0 : s;
}

/// `m:ss` o `h:mm:ss`.
String formatCountdown(int seconds) {
  final h = seconds ~/ 3600, m = seconds % 3600 ~/ 60, s = seconds % 60;
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

/// Texto que mostraría un nodo de texto con [data]; `null` si no es texto
/// o no se puede calcular.
String? _text(LiveNode? node, Map<String, Object?> data, DateTime now) {
  if (node is! LiveText) return null;
  switch (node.kind) {
    case LiveTextKind.bound:
      return '${data[node.source!.field] ?? ''}';
    case LiveTextKind.literal:
      return node.literal;
    case LiveTextKind.format:
      return formatTemplate(node.template!, data);
    case LiveTextKind.countdown:
      return formatCountdown(_remainingSeconds(data[node.source!.field], now));
    case LiveTextKind.stopwatch:
    case LiveTextKind.relative:
      return null;
  }
}

String? _androidText(LiveTextSource? source, Map<String, Object?> data) {
  if (source == null) return null;
  final j = source.toAndroidTextJson();
  if (j['bind'] != null) return '${data[j['bind']] ?? ''}';
  if (j['fmt'] != null) return formatTemplate(j['fmt']! as String, data);
  return j['text'] as String?;
}
