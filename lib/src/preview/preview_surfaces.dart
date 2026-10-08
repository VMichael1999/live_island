import 'dart:ui' show Brightness, ImageFilter;

import 'package:flutter/widgets.dart';

import '../components/actions.dart';
import '../components/layout_nodes.dart';
import '../components/progress.dart';
import '../components/text.dart';
import '../components/visuals.dart';
import '../core/bind.dart' show LiveTextSource;
import '../core/countdown.dart';
import '../core/enums.dart';
import '../core/layout.dart';
import '../core/node.dart';
import 'preview_config.dart';
import 'preview_icon.dart';
import 'preview_nodes.dart';
import 'preview_style.dart';

const _black = Color(0xFF000000);

/// Estilo base: sin subrayado, para que el texto se vea igual dentro o fuera
/// de un `Material`.
Widget _base({required Widget child, Color color = const Color(0xFFFFFFFF)}) =>
    DefaultTextStyle.merge(
      style: TextStyle(
        decoration: TextDecoration.none,
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.3,
      ),
      child: child,
    );

LiveToneStyle _islandStyle(LiveLayout l) =>
    LiveToneStyle(LiveTone.dark, l.theme.accent, mutedAlpha: .62);

LiveTone _lockTone(LiveLayout l, Brightness b) => switch (l.theme.background) {
  LiveBackground.system =>
    b == Brightness.dark ? LiveTone.dark : LiveTone.light,
  LiveBackground.light => LiveTone.light,
  LiveBackground.accent => LiveTone.accent,
};

// ------------------------------------------------------------------ compact

/// Isla compacta: ícono a la izquierda y dato destacado a la derecha.
class LiveCompactPreview extends StatelessWidget {
  const LiveCompactPreview(this.config, {super.key});

  final LivePreviewConfig config;

  @override
  Widget build(BuildContext context) => LivePreviewClock(
    fixed: config.now,
    builder: (context, now) {
      final ctx = LiveRenderContext(
        config: config,
        now: now,
        style: _islandStyle(config.layout),
      );
      final l = config.layout;
      return _base(
        child: Container(
          width: 236,
          height: 37,
          padding: const EdgeInsets.only(left: 10, right: 12),
          decoration: BoxDecoration(
            color: _black,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 72),
                child:
                    l.compactLeading == null
                        ? const SizedBox.shrink()
                        : buildLiveNode(
                          l.compactLeading!,
                          ctx,
                          slot: 22,
                          iconSize: 18,
                        ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 72),
                child:
                    l.compactTrailing == null
                        ? const SizedBox.shrink()
                        : Align(
                          alignment: Alignment.centerRight,
                          child: buildLiveNode(l.compactTrailing!, ctx),
                        ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ------------------------------------------------------------------ minimal

/// Isla mínima (37 × 37 pt). Con [withOtherActivity] se dibuja junto a una
/// segunda actividad, que es cuando iOS la usa.
class LiveMinimalPreview extends StatelessWidget {
  const LiveMinimalPreview(
    this.config, {
    super.key,
    this.withOtherActivity = true,
  });

  final LivePreviewConfig config;
  final bool withOtherActivity;

  @override
  Widget build(BuildContext context) => LivePreviewClock(
    fixed: config.now,
    builder: (context, now) {
      final ctx = LiveRenderContext(
        config: config,
        now: now,
        style: _islandStyle(config.layout),
      );
      final node = config.layout.minimal;
      final isRing = node is LiveProgress && node.isRing;
      final inner =
          node == null
              ? const SizedBox.shrink()
              : buildLiveNode(
                node,
                ctx,
                slot: isRing ? 33 : 24,
                iconSize: isRing ? 14 : 18,
              );
      return _base(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 37,
              height: 37,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _black,
                shape: BoxShape.circle,
              ),
              child: inner,
            ),
            if (withOtherActivity) ...[
              const SizedBox(width: 10),
              Opacity(
                opacity: .55,
                child: Container(
                  width: 37,
                  height: 37,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _black,
                    shape: BoxShape.circle,
                  ),
                  child: const LiveSymbolIcon(
                    'timer',
                    size: 16,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

// ----------------------------------------------------------------- expandida

/// Parte superior (ícono, texto y dato) y parte inferior de una tarjeta.
Widget _topAndBottom({
  required LiveRenderContext ctx,
  required Widget? leading,
  required LiveNode? center,
  required LiveNode? trailing,
  required LiveNode? bottom,
  required double trailingMax,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 12)],
          Expanded(
            child:
                center == null
                    ? const SizedBox.shrink()
                    : buildLiveNode(center, ctx),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: trailingMax),
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: 1,
                child: buildLiveNode(
                  trailing,
                  ctx,
                  slot: 46,
                  align: LiveAlign.end,
                ),
              ),
            ),
          ],
        ],
      ),
      if (bottom != null) ...[
        const SizedBox(height: 12),
        buildLiveNode(bottom, ctx),
      ],
    ],
  );
}

/// Isla expandida (esquinas de 44 pt, negra).
class LiveExpandedPreview extends StatelessWidget {
  const LiveExpandedPreview(this.config, {super.key});

  final LivePreviewConfig config;

  @override
  Widget build(BuildContext context) => LivePreviewClock(
    fixed: config.now,
    builder: (context, now) {
      final ctx = LiveRenderContext(
        config: config,
        now: now,
        style: _islandStyle(config.layout),
      );
      final e = config.layout.expanded ?? const LiveExpanded();
      return _base(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          decoration: BoxDecoration(
            color: _black,
            borderRadius: BorderRadius.circular(44),
          ),
          child: _topAndBottom(
            ctx: ctx,
            leading:
                e.leading == null
                    ? null
                    : buildLiveNode(e.leading!, ctx, slot: 46, iconSize: 38),
            center: e.center,
            trailing: e.trailing,
            bottom: e.bottom,
            trailingMax: 130,
          ),
        ),
      );
    },
  );
}

// ------------------------------------------------------------------- bloqueo

/// Tarjeta de la pantalla de bloqueo (esquinas de 22 pt).
class LiveLockScreenPreview extends StatelessWidget {
  const LiveLockScreenPreview(this.config, {super.key});

  final LivePreviewConfig config;

  @override
  Widget build(BuildContext context) => LivePreviewClock(
    fixed: config.now,
    builder: (context, now) {
      final l = config.layout;
      final tone = _lockTone(l, config.brightness);
      final style = LiveToneStyle(tone, l.theme.accent);
      final ctx = LiveRenderContext(config: config, now: now, style: style);

      final custom = l.lockScreen?.custom;
      final e = l.expanded ?? const LiveExpanded();
      final content =
          custom != null
              ? buildLiveNode(custom, ctx)
              : _topAndBottom(
                ctx: ctx,
                leading: _lockLeading(l, ctx),
                center: e.center,
                trailing: e.trailing,
                bottom: e.bottom,
                trailingMax: 124,
              );

      final card = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: switch (tone) {
            LiveTone.dark => const Color(0xC7161618),
            LiveTone.light => const Color(0xDBFAFAFC),
            LiveTone.accent => l.theme.accent,
          },
        ),
        child: content,
      );
      return _base(
        color: style.fg,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child:
              tone == LiveTone.accent
                  ? card
                  : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: card,
                  ),
        ),
      );
    },
  );
}

/// Ícono de la app en la tarjeta de bloqueo (40 pt): logo, avatar o ícono
/// sobre un cuadro de acento.
Widget? _lockLeading(LiveLayout l, LiveRenderContext ctx) {
  final logo = l.appLogo;
  if (logo is LiveImage) return liveImageBox(logo, 40, ctx);
  final lead = l.expanded?.leading;
  final style = ctx.style;
  if (lead is LiveAvatar) {
    return liveAvatar(
      lead,
      40,
      ctx,
      background: style.isAccent ? const Color(0x40FFFFFF) : null,
    );
  }
  if (lead is LiveImage) return liveImageBox(lead, 40, ctx);
  final icon =
      logo is LiveIcon
          ? logo
          : (lead is LiveBox && lead.child is LiveIcon
              ? lead.child! as LiveIcon
              : null);
  if (icon == null) return null;
  return Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: style.isAccent ? const Color(0x38FFFFFF) : style.accent,
      borderRadius: BorderRadius.circular(11),
    ),
    child: liveSymbol(icon, 22, ctx, color: const Color(0xFFFFFFFF)),
  );
}

// ------------------------------------------------------------------- Android

/// Notificación de Android con su chip de Live Update.
class LiveAndroidPreview extends StatelessWidget {
  const LiveAndroidPreview(this.config, {super.key});

  final LivePreviewConfig config;

  @override
  Widget build(BuildContext context) => LivePreviewClock(
    fixed: config.now,
    builder: (context, now) => _android(config, now),
  );
}

String _androidText(LiveTextSource? source, LiveRenderContext ctx) {
  if (source == null) return '';
  final j = source.toAndroidTextJson();
  if (j['bind'] != null) return '${ctx.state[j['bind']] ?? ''}';
  if (j['fmt'] != null) {
    return (j['fmt']! as String).replaceAllMapped(
      RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}'),
      (m) => '${ctx.state[m[1]] ?? ''}',
    );
  }
  return '${j['text'] ?? ''}';
}

Widget _android(LivePreviewConfig config, DateTime now) {
  final l = config.layout;
  final dark = config.brightness == Brightness.dark;
  final t = AndroidTokens.of(config.brightness);
  final style = LiveToneStyle(
    dark ? LiveTone.dark : LiveTone.light,
    l.theme.accent,
  );
  final ctx = LiveRenderContext(config: config, now: now, style: style);
  final a = l.android;
  final colorized = a?.colorized ?? false;
  final accent = l.theme.accent;

  final baseTitle = _androidText(a?.title, ctx);
  var title = baseTitle;
  final trailing = l.compactTrailing;
  final highlightText =
      trailing is LiveText && trailing.kind != LiveTextKind.countdown
          ? liveTextOf(trailing, ctx)
          : '';
  if (highlightText.isNotEmpty) title = '$title · $highlightText';
  final when =
      trailing is LiveText && trailing.kind == LiveTextKind.countdown
          ? formatCountdown(
            remainingSeconds(ctx.state[trailing.source!.field], now),
          )
          : 'ahora';

  final promoted =
      !colorized && config.androidPromotable && baseTitle.isNotEmpty;

  // Ícono pequeño: silueta de un solo color (ver docs/PROMPT.md §5.1).
  Widget smallIcon(double size) {
    final src = l.androidSmallIcon ?? l.appLogo;
    if (src is LiveImage) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcIn),
        child: liveImageBox(src, size, ctx, shape: LiveShape.square),
      );
    }
    final icon =
        src is LiveIcon
            ? src
            : (l.compactLeading is LiveIcon
                ? l.compactLeading! as LiveIcon
                : null);
    if (icon != null) {
      return liveSymbol(
        icon,
        size,
        ctx,
        color: const Color(0xFFFFFFFF),
        strokeWidth: 2.4,
      );
    }
    return SizedBox.square(dimension: size);
  }

  Widget? largeIcon() {
    final lead = l.expanded?.leading ?? l.compactLeading;
    if (lead is LiveAvatar) return liveAvatar(lead, 40, ctx);
    if (l.appLogo is LiveImage) {
      return liveImageBox(l.appLogo! as LiveImage, 40, ctx);
    }
    if (lead is LiveImage) return liveImageBox(lead, 40, ctx);
    return null;
  }

  // Barra: la de Android, o la primera de la isla expandida. El anillo no existe.
  var progress =
      a?.progress ?? firstProgress(l.expanded?.nodes ?? const <LiveNode>[]);
  if (progress is LiveProgress && progress.isRing) {
    progress = LiveProgress.bar(value: progress.value);
  }

  final buttons =
      a?.actions ??
      [
        for (final n in (l.expanded?.bottom?.descendants ?? const <LiveNode>[]))
          if (n is LiveButton) n,
      ];

  final chip = _chipOf(a?.chip, ctx);
  final cardBg = colorized ? accent : t.card;
  final titleColor = colorized ? const Color(0xFFFFFFFF) : t.title;
  final bodyColor = colorized ? const Color(0xD9FFFFFF) : t.body;
  final large = largeIcon();

  return _base(
    color: t.status,
    child: Container(
      decoration: BoxDecoration(
        color: t.shade,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text(
                  '9:41',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (promoted && chip != null) ...[
                  const SizedBox(width: 8),
                  _chipWidget(chip, accent, smallIcon(14)),
                ],
                const Spacer(),
                LiveSymbolIcon('signal', size: 15, color: t.status),
                const SizedBox(width: 8),
                LiveSymbolIcon('wifi', size: 15, color: t.status),
                const SizedBox(width: 8),
                LiveSymbolIcon('batteryfull', size: 17, color: t.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorized ? const Color(0x40FFFFFF) : accent,
                        ),
                        child: smallIcon(13),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${config.appName} · $when',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorized ? const Color(0xFFFFFFFF) : t.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: titleColor,
                              ),
                            ),
                            Text(
                              _androidText(a?.text, ctx),
                              style: TextStyle(
                                fontSize: 14,
                                color: bodyColor,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (large != null) ...[const SizedBox(width: 12), large],
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 10),
                    buildLiveNode(progress, ctx),
                  ],
                  if (buttons.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        for (final b in buttons)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (b.icon is LiveIcon) ...[
                                liveSymbol(
                                  b.icon! as LiveIcon,
                                  16,
                                  ctx,
                                  color:
                                      colorized
                                          ? const Color(0xFFFFFFFF)
                                          : accent,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                b.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      colorized
                                          ? const Color(0xFFFFFFFF)
                                          : accent,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              promoted
                  ? 'Promovida a Live Update: chip en la barra de estado, arriba del panel y en la pantalla de bloqueo.'
                  : 'No se promueve: se ve como notificación en curso normal, sin chip.',
              style: TextStyle(fontSize: 12, color: t.body),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Texto del chip y cómo se muestra (mismo criterio que `chipInfo` del HTML).
({String shown, bool onlyIcon})? _chipOf(
  LiveChip? chip,
  LiveRenderContext ctx,
) {
  if (chip == null) return null;
  final text = switch (chip.type) {
    'countdown' =>
      '${remainingMinutes(ctx.state[chip.bind!.field], ctx.now)} min',
    'text' => chip.text ?? '',
    _ => '',
  };
  final runes = text.runes.toList();
  if (text.isEmpty || runes.length > 12) return (shown: '', onlyIcon: true);
  if (runes.length > 7) {
    return (shown: '${String.fromCharCodes(runes.take(6))}…', onlyIcon: false);
  }
  return (shown: text, onlyIcon: false);
}

Widget _chipWidget(
  ({String shown, bool onlyIcon}) chip,
  Color accent,
  Widget icon,
) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 96),
    child: Container(
      height: 24,
      padding: EdgeInsets.only(left: 7, right: chip.onlyIcon ? 7 : 9),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          if (!chip.onlyIcon) ...[
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                chip.shown,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
