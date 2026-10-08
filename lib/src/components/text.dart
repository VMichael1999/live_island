import 'dart:ui' show Color;

import '../core/bind.dart';
import '../core/enums.dart';
import '../core/json_util.dart';
import '../core/node.dart';

/// De dónde sale el texto.
enum LiveTextKind { bound, literal, format, countdown, stopwatch, relative }

/// Texto. Puede venir de un campo del estado, ser literal, una plantilla o un
/// contador que corre solo (cuenta regresiva, cronómetro, tiempo relativo).
class LiveText extends LiveNode implements LiveTextSource {
  /// Texto de un campo del estado: `LiveText(bind('titulo'))`.
  const LiveText(
    LiveBind this.source, {
    this.size,
    this.weight,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  })  : kind = LiveTextKind.bound,
        literal = null,
        template = null;

  /// Texto fijo.
  const LiveText.literal(
    String this.literal, {
    this.size,
    this.weight,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  })  : kind = LiveTextKind.literal,
        source = null,
        template = null;

  /// Plantilla con campos entre llaves: `'{subtitulo} · {nombre}'`.
  const LiveText.format(
    String this.template, {
    this.size,
    this.weight,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  })  : kind = LiveTextKind.format,
        source = null,
        literal = null;

  /// Cuenta regresiva hasta la fecha del campo [until]. Corre sola.
  const LiveText.countdown(
    LiveBind until, {
    this.size,
    this.weight,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  })  : kind = LiveTextKind.countdown,
        source = until,
        literal = null,
        template = null;

  /// Cronómetro desde la fecha del campo [since].
  const LiveText.stopwatch(
    LiveBind since, {
    this.size,
    this.weight,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  })  : kind = LiveTextKind.stopwatch,
        source = since,
        literal = null,
        template = null;

  /// Tiempo relativo a la fecha del campo [date] ("hace 3 min", "en 5 min").
  const LiveText.relative(
    LiveBind date, {
    this.size,
    this.weight,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  })  : kind = LiveTextKind.relative,
        source = date,
        literal = null,
        template = null;

  /// Copia de [other] con otro estilo: `LiveText.from(otro, size: 22)`.
  LiveText.from(
    LiveText other, {
    double? size,
    int? weight,
    bool? muted,
    bool? accent,
    Color? color,
    int? lines,
    LiveAlign? align,
    bool? tabular,
  })  : kind = other.kind,
        source = other.source,
        literal = other.literal,
        template = other.template,
        size = size ?? other.size,
        weight = weight ?? other.weight,
        muted = muted ?? other.muted,
        accent = accent ?? other.accent,
        color = color ?? other.color,
        lines = lines ?? other.lines,
        align = align ?? other.align,
        tabular = tabular ?? other.tabular;

  final LiveTextKind kind;
  final LiveBind? source;
  final String? literal;
  final String? template;

  /// Tamaño en pt (15 por defecto).
  final double? size;

  /// Peso de la fuente: 400, 600, 700…
  final int? weight;
  final bool muted;
  final bool accent;
  final Color? color;

  /// Máximo de líneas; el resto se recorta con elipsis.
  final int? lines;
  final LiveAlign? align;

  /// Cifras tabulares (activas por defecto en contadores).
  final bool? tabular;

  @override
  String get type => switch (kind) {
        LiveTextKind.countdown => 'countdown',
        LiveTextKind.stopwatch => 'stopwatch',
        LiveTextKind.relative => 'relative',
        _ => 'text',
      };

  @override
  Map<String, Object?> toAndroidTextJson() => switch (kind) {
        LiveTextKind.bound => {'bind': source!.field},
        LiveTextKind.literal => {'text': literal},
        LiveTextKind.format => {'fmt': template},
        _ => throw UnsupportedError(
            'Android solo admite texto enlazado, literal o con plantilla en '
            'el título y el texto de la notificación.'),
      };

  @override
  Map<String, Object?> toJson() => compact({
        't': type,
        'bind': source?.field,
        'text': literal,
        'fmt': template,
        'size': size,
        'w': weight,
        'muted': muted ? true : null,
        'accent': accent ? true : null,
        'color': color == null ? null : colorToHex(color!),
        'lines': lines,
        'align': align?.name,
        'tabular': tabular,
      });

  factory LiveText.fromJson(Map<String, Object?> json) {
    final size = (json['size'] as num?)?.toDouble();
    final weight = (json['w'] as num?)?.toInt();
    final muted = json['muted'] == true;
    final accent = json['accent'] == true;
    final color =
        json['color'] == null ? null : colorFromHex(json['color']! as String);
    final lines = (json['lines'] as num?)?.toInt();
    final align = json['align'] == null
        ? null
        : enumByName(LiveAlign.values, json['align'], LiveAlign.start);
    final tabular = json['tabular'] as bool?;
    LiveBind b() => LiveBind(json['bind']! as String);
    LiveText Function(LiveBind) timed = switch (json['t']) {
      'countdown' => (x) => LiveText.countdown(x,
          size: size, weight: weight, muted: muted, accent: accent,
          color: color, lines: lines, align: align, tabular: tabular),
      'stopwatch' => (x) => LiveText.stopwatch(x,
          size: size, weight: weight, muted: muted, accent: accent,
          color: color, lines: lines, align: align, tabular: tabular),
      'relative' => (x) => LiveText.relative(x,
          size: size, weight: weight, muted: muted, accent: accent,
          color: color, lines: lines, align: align, tabular: tabular),
      _ => (x) => LiveText(x,
          size: size, weight: weight, muted: muted, accent: accent,
          color: color, lines: lines, align: align, tabular: tabular),
    };
    if (json['t'] == 'text' && json['text'] != null) {
      return LiveText.literal(json['text']! as String,
          size: size, weight: weight, muted: muted, accent: accent,
          color: color, lines: lines, align: align, tabular: tabular);
    }
    if (json['t'] == 'text' && json['fmt'] != null) {
      return LiveText.format(json['fmt']! as String,
          size: size, weight: weight, muted: muted, accent: accent,
          color: color, lines: lines, align: align, tabular: tabular);
    }
    return timed(b());
  }
}
