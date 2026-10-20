import 'dart:ui' show Color;

import '../core/bind.dart';
import '../core/enums.dart';
import '../core/json_util.dart';
import '../core/node.dart';

/// Where the text comes from.
enum LiveTextKind { bound, literal, format, countdown, stopwatch, relative }

/// Text. It can come from a state field, be a literal, a template or a
/// counter that runs on its own (countdown, stopwatch, relative time).
class LiveText extends LiveNode implements LiveTextSource {
  /// Text from a state field: `LiveText(bind('title'))`.
  const LiveText(
    LiveBind this.source, {
    this.size,
    this.weight,
    this.italic = false,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  }) : kind = LiveTextKind.bound,
       literal = null,
       template = null;

  /// Fixed text.
  const LiveText.literal(
    String this.literal, {
    this.size,
    this.weight,
    this.italic = false,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  }) : kind = LiveTextKind.literal,
       source = null,
       template = null;

  /// Template with fields between braces: `'{subtitle} · {name}'`.
  const LiveText.format(
    String this.template, {
    this.size,
    this.weight,
    this.italic = false,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  }) : kind = LiveTextKind.format,
       source = null,
       literal = null;

  /// Countdown to the date in the [until] field. It runs on its own.
  const LiveText.countdown(
    LiveBind until, {
    this.size,
    this.weight,
    this.italic = false,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  }) : kind = LiveTextKind.countdown,
       source = until,
       literal = null,
       template = null;

  /// Stopwatch from the date in the [since] field.
  const LiveText.stopwatch(
    LiveBind since, {
    this.size,
    this.weight,
    this.italic = false,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  }) : kind = LiveTextKind.stopwatch,
       source = since,
       literal = null,
       template = null;

  /// Time relative to the date in the [date] field ("3 min ago", "in 5 min").
  const LiveText.relative(
    LiveBind date, {
    this.size,
    this.weight,
    this.italic = false,
    this.muted = false,
    this.accent = false,
    this.color,
    this.lines,
    this.align,
    this.tabular,
  }) : kind = LiveTextKind.relative,
       source = date,
       literal = null,
       template = null;

  /// Copy of [other] with another style: `LiveText.from(other, size: 22)`.
  LiveText.from(
    LiveText other, {
    double? size,
    int? weight,
    bool? italic,
    bool? muted,
    bool? accent,
    Color? color,
    int? lines,
    LiveAlign? align,
    bool? tabular,
  }) : kind = other.kind,
       source = other.source,
       literal = other.literal,
       template = other.template,
       size = size ?? other.size,
       weight = weight ?? other.weight,
       italic = italic ?? other.italic,
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

  /// Size in pt (15 by default).
  final double? size;

  /// Font weight: 400, 600, 700…
  final int? weight;

  /// Italic.
  final bool italic;
  final bool muted;
  final bool accent;
  final Color? color;

  /// Maximum lines; the rest is cut with an ellipsis.
  final int? lines;
  final LiveAlign? align;

  /// Tabular figures (on by default in counters).
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
    _ =>
      throw UnsupportedError(
        'Android only supports bound, literal or templated text in '
        'the notification title and text.',
      ),
  };

  @override
  Map<String, Object?> toJson() => compact({
    't': type,
    'bind': source?.field,
    'text': literal,
    'fmt': template,
    'size': size,
    'w': weight,
    'i': italic ? true : null,
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
    final italic = json['i'] == true;
    final muted = json['muted'] == true;
    final accent = json['accent'] == true;
    final color =
        json['color'] == null ? null : colorFromHex(json['color']! as String);
    final lines = (json['lines'] as num?)?.toInt();
    final align =
        json['align'] == null
            ? null
            : enumByName(LiveAlign.values, json['align'], LiveAlign.start);
    final tabular = json['tabular'] as bool?;
    LiveBind b() => LiveBind(json['bind']! as String);
    LiveText Function(LiveBind) timed = switch (json['t']) {
      'countdown' =>
        (x) => LiveText.countdown(
          x,
          size: size,
          weight: weight,
          italic: italic,
          muted: muted,
          accent: accent,
          color: color,
          lines: lines,
          align: align,
          tabular: tabular,
        ),
      'stopwatch' =>
        (x) => LiveText.stopwatch(
          x,
          size: size,
          weight: weight,
          italic: italic,
          muted: muted,
          accent: accent,
          color: color,
          lines: lines,
          align: align,
          tabular: tabular,
        ),
      'relative' =>
        (x) => LiveText.relative(
          x,
          size: size,
          weight: weight,
          italic: italic,
          muted: muted,
          accent: accent,
          color: color,
          lines: lines,
          align: align,
          tabular: tabular,
        ),
      _ =>
        (x) => LiveText(
          x,
          size: size,
          weight: weight,
          italic: italic,
          muted: muted,
          accent: accent,
          color: color,
          lines: lines,
          align: align,
          tabular: tabular,
        ),
    };
    if (json['t'] == 'text' && json['text'] != null) {
      return LiveText.literal(
        json['text']! as String,
        size: size,
        weight: weight,
        italic: italic,
        muted: muted,
        accent: accent,
        color: color,
        lines: lines,
        align: align,
        tabular: tabular,
      );
    }
    if (json['t'] == 'text' && json['fmt'] != null) {
      return LiveText.format(
        json['fmt']! as String,
        size: size,
        weight: weight,
        italic: italic,
        muted: muted,
        accent: accent,
        color: color,
        lines: lines,
        align: align,
        tabular: tabular,
      );
    }
    return timed(b());
  }
}
