import 'dart:convert';
import 'dart:math' as math;

import '../components/charts.dart';
import '../components/progress.dart';
import '../components/text.dart';
import '../components/visuals.dart';
import 'bind.dart';
import 'countdown.dart';
import 'enums.dart';
import 'image_slots.dart';
import 'layout.dart';
import 'node.dart';
import 'state.dart';

/// 4,096-byte limit, written as in the prototype HTML.
const _maxBytesLabel = '4 096';

/// Severity of a [LiveIsland.check] warning.
enum LiveSeverity { ok, warn, bad }

/// A warning from the validation report.
class LiveCheck {
  const LiveCheck(this.severity, this.code, this.message);

  final LiveSeverity severity;

  /// Stable identifier for tests and filters.
  final String code;
  final String message;

  @override
  String toString() => '[${severity.name}] $message';
}

/// Result of validating a design with its state.
class LiveReport {
  const LiveReport(this.items);

  final List<LiveCheck> items;

  bool get hasErrors => items.any((c) => c.severity == LiveSeverity.bad);
  bool get hasWarnings => items.any((c) => c.severity == LiveSeverity.warn);

  /// First warning with the given [code], if any.
  LiveCheck? byCode(String code) {
    for (final c in items) {
      if (c.code == code) return c;
    }
    return null;
  }

  @override
  String toString() => items.join('\n');
}

/// Validates [layout] with [state] using the same criteria as the "Validation"
/// panel of the prototype HTML.
///
/// [now] fixes the instant used for the countdowns.
/// [androidPromotable] is `false` for cases Google does not promote to Live
/// Update (ads, chats, activities the user did not start).
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
  if (android?.style == LiveAndroidStyle.card) {
    rows.add(
      const LiveCheck(
        LiveSeverity.warn,
        'androidCard',
        'Android: la tarjeta con tu diseño (style card) no se promueve a Live Update ni muestra chip en la barra de estado. Pide Android 12 o más; antes se usa el estilo nativo.',
      ),
    );
  }
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
      android?.progress ??
      firstProgress(layout.expanded?.nodes ?? const <LiveNode>[]);
  if ((androidProgress is LiveProgress && androidProgress.isRing ||
      androidProgress is LiveGauge)) {
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
  for (final slot in imageSlots(layout)) {
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

enum _ChipMode { full, cut, icon }

/// Same criteria as `chipInfo` in the HTML.
({String text, _ChipMode mode, int length})? _chip(
  LiveChip? chip,
  Map<String, Object?> data,
  DateTime now,
) {
  if (chip == null) return null;
  var text = switch (chip.type) {
    'countdown' => '${remainingMinutes(data[chip.bind!.field], now)} min',
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

/// Text a text node would show with [data]; `null` if it is not text or
/// cannot be computed.
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
      return formatCountdown(remainingSeconds(data[node.source!.field], now));
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
