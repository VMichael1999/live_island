import 'dart:io' show File;

import 'package:flutter/widgets.dart';

import '../components/actions.dart';
import '../components/layout_nodes.dart';
import '../components/progress.dart';
import '../components/text.dart';
import '../components/visuals.dart';
import '../core/bind.dart';
import '../core/countdown.dart';
import '../core/enums.dart';
import '../core/node.dart';
import 'preview_config.dart';
import 'preview_icon.dart';
import 'preview_progress.dart';
import 'preview_style.dart';

/// Contexto de un dibujado: datos, hora y colores de la superficie.
class LiveRenderContext {
  LiveRenderContext({
    required this.config,
    required this.now,
    required this.style,
    this.island = false,
  });

  final LivePreviewConfig config;
  final DateTime now;
  final LiveToneStyle style;

  /// `true` en la isla expandida: no dibuja botones, porque tocar la isla
  /// siempre abre la app (ver docs/design/DESVIACIONES.md).
  final bool island;

  int _buttons = 0;

  /// Posición del siguiente botón en esta superficie (0 = principal).
  int nextButton() => _buttons++;

  Map<String, Object?> get state => config.state;

  ImageProvider? providerFor(LiveImage img) {
    final given = config.images[img.id];
    if (given != null) return given;
    return switch (img.source) {
      LiveImageSource.asset => AssetImage(img.key),
      LiveImageSource.network => NetworkImage(img.key),
      LiveImageSource.file => FileImage(File(img.key)),
      LiveImageSource.memory => MemoryImage(img.bytes!),
      LiveImageSource.reference => null,
    };
  }
}

/// ¿Este nodo no se dibuja en este contexto? (Botones dentro de la isla.)
bool _hidden(LiveNode n, LiveRenderContext ctx) {
  if (!ctx.island) return false;
  if (n is LiveButton || n is LiveToggle) return true;
  if (n is LiveRow) {
    return n.items.isNotEmpty &&
        n.items.every(
          (c) => c is LiveButton || c is LiveToggle || c is LiveSpacer,
        );
  }
  return false;
}

/// Recuadro neutro cuando una imagen no se puede cargar.
const _missingImage = DecoratedBox(
  decoration: BoxDecoration(color: Color(0x33808080)),
);

double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

/// Nombre con el que buscar el ícono: el SF Symbol o el archivo de Android.
String _androidName(String path) =>
    path
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[A-Za-z0-9]+$'), '')
        .toLowerCase();

/// Dibuja [node]. [slot] es el tamaño de la zona donde va (para íconos,
/// imágenes y avatares sin `size`); [iconSize] el glifo si es un ícono.
Widget buildLiveNode(
  LiveNode node,
  LiveRenderContext ctx, {
  double? slot,
  double? iconSize,
  Axis axis = Axis.vertical,
  LiveAlign? align,
}) {
  switch (node) {
    case LiveRow():
      return _row(node, ctx);
    case LiveColumn():
      return _column(node, ctx);
    case LiveStack():
      return Stack(
        alignment: _stackAlign(node.align),
        children: [for (final c in node.items) buildLiveNode(c, ctx)],
      );
    case LiveSpacer():
      return axis == Axis.horizontal && node.size == null
          ? const Expanded(child: SizedBox.shrink())
          : SizedBox(width: node.size, height: node.size);
    case LivePadding():
      return Padding(
        padding: EdgeInsets.only(
          left: node.left ?? node.horizontal ?? node.all ?? 0,
          right: node.right ?? node.horizontal ?? node.all ?? 0,
          top: node.top ?? node.vertical ?? node.all ?? 0,
          bottom: node.bottom ?? node.vertical ?? node.all ?? 0,
        ),
        child: buildLiveNode(node.child, ctx),
      );
    case LiveBox():
      final size = node.size;
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              node.color ??
              (node.tint == null
                  ? null
                  : ctx.style.accent.withValues(alpha: node.tint!)),
          borderRadius:
              node.radius == null ? null : BorderRadius.circular(node.radius!),
        ),
        child:
            node.child == null
                ? null
                : buildLiveNode(
                  node.child!,
                  ctx,
                  slot: size == null ? null : size * .52,
                  iconSize: size == null ? null : size * .52,
                ),
      );
    case LiveIf():
      final branch = node.when.evaluate(ctx.state) ? node.then : node.otherwise;
      return branch == null
          ? const SizedBox.shrink()
          : buildLiveNode(
            branch,
            ctx,
            slot: slot,
            iconSize: iconSize,
            axis: axis,
            align: align,
          );
    case LiveText():
      return _text(node, ctx, align);
    case LiveVisual():
      return _visual(node, ctx, slot: slot, iconSize: iconSize);
    case LiveProgress():
      return _progress(node, ctx, slot: slot);
    case LiveSegments():
      return _bar(
        ctx,
        value: _num(ctx.state[node.value.field]),
        style: node.style,
        labels: node.labels,
        segmented: true,
        points: node.points,
        showLabels: node.showLabels,
        tracker: node.tracker,
        start: node.startIcon,
        end: node.endIcon,
      );
    case LiveMetric():
      return _metric(node, ctx);
    case LiveButton():
      return _hidden(node, ctx)
          ? const SizedBox.shrink()
          : _button(node.label, node.icon, ctx);
    case LiveToggle():
      return _hidden(node, ctx)
          ? const SizedBox.shrink()
          : _button(node.label ?? node.id, node.icon, ctx);
    default:
      return const SizedBox.shrink();
  }
}

AlignmentGeometry _stackAlign(LiveAlign? a) => switch (a) {
  LiveAlign.start => Alignment.centerLeft,
  LiveAlign.end => Alignment.centerRight,
  _ => Alignment.center,
};

List<Widget> _spaced(List<Widget> items, double gap, Axis axis) => [
  for (var i = 0; i < items.length; i++) ...[
    if (i > 0 && gap > 0)
      axis == Axis.horizontal ? SizedBox(width: gap) : SizedBox(height: gap),
    items[i],
  ],
];

Widget _row(LiveRow node, LiveRenderContext ctx) {
  final gap = node.gap ?? 8;
  final hasSpacer = node.items.any((c) => c is LiveSpacer && c.size == null);
  final hasButtons = node.items.any((c) => c is LiveButton || c is LiveToggle);
  final cross = switch (node.align) {
    LiveAlign.start => CrossAxisAlignment.start,
    LiveAlign.end => CrossAxisAlignment.end,
    _ => CrossAxisAlignment.center,
  };
  if (hasButtons && !hasSpacer) {
    return Wrap(
      spacing: gap,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in node.items)
          buildLiveNode(c, ctx, axis: Axis.horizontal),
      ],
    );
  }
  final children = [
    for (final c in node.items)
      c is LiveText && !hasSpacer
          ? Flexible(child: buildLiveNode(c, ctx, axis: Axis.horizontal))
          : buildLiveNode(c, ctx, axis: Axis.horizontal),
  ];
  return Row(
    mainAxisSize: hasSpacer ? MainAxisSize.max : MainAxisSize.min,
    crossAxisAlignment: cross,
    children: _spaced(children, gap, Axis.horizontal),
  );
}

Widget _column(LiveColumn node, LiveRenderContext ctx) {
  final cross = switch (node.align) {
    LiveAlign.end => CrossAxisAlignment.end,
    LiveAlign.center => CrossAxisAlignment.center,
    _ => CrossAxisAlignment.start,
  };
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: cross,
    children: _spaced(
      [
        for (final c in node.items)
          if (!_hidden(c, ctx)) buildLiveNode(c, ctx, align: node.align),
      ],
      node.gap ?? 2,
      Axis.vertical,
    ),
  );
}

// ---------------------------------------------------------------- texto

String liveTextOf(LiveText t, LiveRenderContext ctx) {
  switch (t.kind) {
    case LiveTextKind.bound:
      return '${ctx.state[t.source!.field] ?? ''}';
    case LiveTextKind.literal:
      return t.literal!;
    case LiveTextKind.format:
      return formatTemplate(t.template!, ctx.state);
    case LiveTextKind.countdown:
      return formatCountdown(
        remainingSeconds(ctx.state[t.source!.field], ctx.now),
      );
    case LiveTextKind.stopwatch:
      return formatCountdown(
        elapsedSeconds(ctx.state[t.source!.field], ctx.now),
      );
    case LiveTextKind.relative:
      final d = DateTime.tryParse('${ctx.state[t.source!.field]}');
      if (d == null) return '';
      final min = (d.difference(ctx.now).inSeconds / 60).round();
      if (min == 0) return 'ahora';
      return min > 0 ? 'en $min min' : 'hace ${-min} min';
  }
}

FontWeight _weight(int? w) => switch (w) {
  null => FontWeight.w400,
  <= 100 => FontWeight.w100,
  <= 200 => FontWeight.w200,
  <= 300 => FontWeight.w300,
  <= 400 => FontWeight.w400,
  <= 500 => FontWeight.w500,
  <= 600 => FontWeight.w600,
  <= 700 => FontWeight.w700,
  <= 800 => FontWeight.w800,
  _ => FontWeight.w900,
};

Widget _text(LiveText t, LiveRenderContext ctx, LiveAlign? inherited) {
  final size = t.size ?? 15;
  final counter =
      t.kind == LiveTextKind.countdown || t.kind == LiveTextKind.stopwatch;
  final lines = t.lines ?? 1;
  final al = t.align ?? inherited;
  return Text(
    liveTextOf(t, ctx),
    maxLines: lines,
    softWrap: lines > 1,
    overflow: TextOverflow.ellipsis,
    textAlign: switch (al) {
      LiveAlign.end => TextAlign.end,
      LiveAlign.center => TextAlign.center,
      _ => TextAlign.start,
    },
    style: TextStyle(
      fontSize: size,
      fontWeight: _weight(t.weight),
      height:
          size >= 20
              ? 1.1
              : (t.weight != null && t.weight! >= 600 ? 1.25 : 1.3),
      color:
          t.color ??
          (t.accent
              ? ctx.style.accentOnSurface
              : (t.muted ? ctx.style.muted : ctx.style.fg)),
      fontFeatures:
          (t.tabular ?? counter) ? const [FontFeature.tabularFigures()] : null,
    ),
  );
}

// ---------------------------------------------------------------- visuales

Widget _visual(
  LiveVisual v,
  LiveRenderContext ctx, {
  double? slot,
  double? iconSize,
}) {
  switch (v) {
    case LiveIcon():
      final size = v.size ?? iconSize ?? slot ?? 20;
      return liveSymbol(
        v,
        size,
        ctx,
        color: v.color ?? (v.accent ? ctx.style.accentOnSurface : ctx.style.fg),
      );
    case LiveImage():
      return liveImageBox(v, v.size ?? slot ?? 24, ctx);
    case LiveAvatar():
      return _avatar(v, v.size ?? slot ?? 22, ctx);
  }
}

/// Dibuja el SF Symbol (o su equivalente de Android) de [icon].
Widget liveSymbol(
  LiveIcon icon,
  double size,
  LiveRenderContext ctx, {
  required Color color,
  double strokeWidth = 2.2,
}) {
  var name = icon.sf;
  if (!LiveSymbolIcon.has(name) && icon.android != null) {
    final alt = _androidName(icon.android!);
    if (LiveSymbolIcon.has(alt)) name = alt;
  }
  return LiveSymbolIcon(
    name,
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    fallback: ctx.config.symbolBuilder,
  );
}

/// Imagen propia dentro de un cuadro de [size], con su forma y ajuste.
Widget liveImageBox(
  LiveImage img,
  double size,
  LiveRenderContext ctx, {
  LiveShape? shape,
}) {
  final s = shape ?? img.shape;
  final radius = switch (s) {
    LiveShape.circle => size / 2,
    LiveShape.square => size * .12,
    LiveShape.rounded => (size * .26).roundToDouble(),
  };
  final provider = ctx.providerFor(img);
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: SizedBox.square(
      dimension: size,
      child:
          provider == null
              ? _missingImage
              : Image(
                image: provider,
                fit: img.fit == LiveFit.cover ? BoxFit.cover : BoxFit.contain,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => _missingImage,
              ),
    ),
  );
}

Widget _avatar(
  LiveAvatar a,
  double size,
  LiveRenderContext ctx, {
  Color? background,
}) {
  if (a.photo != null) {
    return liveImageBox(a.photo!, size, ctx, shape: LiveShape.circle);
  }
  final text =
      a.bindText != null
          ? '${ctx.state[a.bindText!.field] ?? ''}'
          : (a.text ?? '');
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: background ?? ctx.style.accent,
    ),
    child: Text(
      text.isEmpty ? '?' : text,
      style: TextStyle(
        fontSize: (size * .42).roundToDouble(),
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
        height: 1,
      ),
    ),
  );
}

/// Avatar de [size] con el fondo indicado (la tarjeta de bloqueo lo aclara
/// cuando su fondo es el color de acento).
Widget liveAvatar(
  LiveAvatar a,
  double size,
  LiveRenderContext ctx, {
  Color? background,
}) => _avatar(a, size, ctx, background: background);

// ---------------------------------------------------------------- progreso

Widget _progress(LiveProgress p, LiveRenderContext ctx, {double? slot}) {
  final value = _num(ctx.state[p.value.field]);
  if (p.isRing) {
    final size = p.size ?? slot ?? 40;
    return LivePreviewRing(
      value: value,
      size: size,
      color: p.style?.color ?? ctx.style.fill,
      strokeWidth: p.style?.height ?? 3,
      trackColor: p.style?.trackColor,
      child:
          p.child == null
              ? null
              : buildLiveNode(p.child!, ctx, slot: 16, iconSize: 14),
    );
  }
  return _bar(
    ctx,
    value: value,
    style: p.style,
    tracker: p.tracker,
    start: p.startIcon,
    end: p.endIcon,
  );
}

/// Barra con todos sus estilos opcionales ([style]).
Widget _bar(
  LiveRenderContext ctx, {
  required double value,
  LiveProgressStyle? style,
  List<String> labels = const [],
  bool segmented = false,
  bool points = false,
  bool showLabels = true,
  LiveTracker? tracker,
  LiveVisual? start,
  LiveVisual? end,
}) {
  final h = style?.height ?? 6;
  return LivePreviewBar(
    value: value,
    style: ctx.style,
    labels: labels,
    segmented: segmented,
    points: points,
    showLabels: showLabels,
    tracker: _tracker(
      tracker,
      ctx,
      size: style?.trackerSize ?? 26,
      fill: style?.color,
    ),
    start: _endIcon(start, ctx),
    end: _endIcon(end, ctx),
    height: h,
    gap: style?.gap ?? 4,
    radius: style?.radius,
    pointSize: style?.pointSize ?? 10,
    labelSize: style?.labelSize ?? 11.5,
    fillColor: style?.color,
    trackColor: style?.trackColor,
    pointColor: style?.pointColor,
    pointShape: style?.pointShape ?? LivePointShape.circle,
  );
}

Widget? _endIcon(LiveVisual? v, LiveRenderContext ctx) {
  if (v == null) return null;
  return switch (v) {
    LiveIcon() => liveSymbol(v, v.size ?? 16, ctx, color: ctx.style.endIcon),
    LiveImage() => liveImageBox(v, v.size ?? 16, ctx),
    LiveAvatar() => liveAvatar(v, v.size ?? 16, ctx),
  };
}

Widget? _tracker(
  LiveTracker? t,
  LiveRenderContext ctx, {
  double size = 26,
  Color? fill,
}) {
  if (t == null) return null;
  final style = ctx.style;
  final k = size / 26;
  Widget circle(Widget child) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: fill ?? style.trackerBg,
      boxShadow: const [
        BoxShadow(
          color: Color(0x59000000),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: child,
  );
  final v = t.visual;
  if (v is LiveIcon) {
    return circle(liveSymbol(v, 15 * k, ctx, color: style.trackerFg));
  }
  if (v is LiveImage) {
    if (t.background == LiveTrackerBackground.accentCircle) {
      return circle(liveImageBox(v, 17 * k, ctx, shape: LiveShape.square));
    }
    return _bareTracker(v, t.height, ctx);
  }
  return null;
}

/// Imagen sin fondo: alto fijo, ancho según su proporción y una sombra suave.
Widget _bareTracker(LiveImage img, double height, LiveRenderContext ctx) {
  final provider = ctx.providerFor(img);
  if (provider == null) return SizedBox(height: height, width: height);
  Widget image() => Image(
    image: provider,
    height: height,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => SizedBox(height: height, width: height),
  );
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 56),
    child: Stack(
      children: [
        Transform.translate(
          offset: const Offset(0, 1),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0x8C000000),
              BlendMode.srcIn,
            ),
            child: image(),
          ),
        ),
        image(),
      ],
    ),
  );
}

// ---------------------------------------------------------------- otros

Widget _metric(LiveMetric m, LiveRenderContext ctx) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${ctx.state[m.value.field] ?? ''}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ctx.style.fg,
            ),
          ),
          if (m.unit != null)
            TextSpan(
              text: ' ${m.unit}',
              style: TextStyle(fontSize: 13, color: ctx.style.muted),
            ),
        ],
      ),
    ),
    if (m.label != null)
      Text(m.label!, style: TextStyle(fontSize: 12, color: ctx.style.muted)),
  ],
);

Widget _button(String label, LiveVisual? icon, LiveRenderContext ctx) {
  final (bg, fg) = ctx.style.button(ctx.nextButton());
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon is LiveIcon) ...[
          liveSymbol(icon, 15, ctx, color: fg),
          const SizedBox(width: 6),
        ],
        if (icon is LiveImage) ...[
          liveImageBox(icon, 15, ctx),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
            height: 1.2,
          ),
        ),
      ],
    ),
  );
}
