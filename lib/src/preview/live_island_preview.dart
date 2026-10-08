import 'dart:ui' show Brightness, FontFeature;

import 'package:flutter/widgets.dart';

import '../core/layout.dart';
import 'preview_config.dart';
import 'preview_surfaces.dart';

/// Superficies que puede dibujar [LiveIslandPreview].
enum LiveSurface { compact, minimal, expanded, lockScreen, android }

/// Réplica en Flutter de lo que muestra el HTML de prototipos: la isla
/// compacta, mínima y expandida, la tarjeta de la pantalla de bloqueo y la
/// notificación de Android. Sirve para probar un diseño sin compilar el
/// Widget Extension.
class LiveIslandPreview extends StatelessWidget {
  LiveIslandPreview({
    super.key,
    required LiveLayout layout,
    required Map<String, Object?> state,
    DateTime? now,
    Map<String, ImageProvider> images = const {},
    Brightness brightness = Brightness.dark,
    String appName = 'Mi app',
    bool androidPromotable = true,
    LiveSymbolBuilder? symbolBuilder,
    this.surfaces = const {
      LiveSurface.compact,
      LiveSurface.minimal,
      LiveSurface.expanded,
      LiveSurface.lockScreen,
      LiveSurface.android,
    },
    this.showLabels = true,
  }) : config = LivePreviewConfig(
         layout: layout,
         state: state,
         now: now,
         images: images,
         brightness: brightness,
         appName: appName,
         androidPromotable: androidPromotable,
         symbolBuilder: symbolBuilder,
       );

  final LivePreviewConfig config;

  /// Qué superficies dibujar, siempre en este orden.
  final Set<LiveSurface> surfaces;

  /// Con `true` se rotula cada superficie con su medida, como en el editor
  /// del HTML, y la pantalla de bloqueo lleva reloj y fecha. Con `false` se
  /// ve como una tarjeta de la galería.
  final bool showLabels;

  static const _label = TextStyle(
    fontSize: 12,
    color: Color(0x9EFFFFFF),
    height: 1.3,
  );

  Widget _section(String label, String measure, Widget child) {
    if (!showLabels) return Center(child: child);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: _label)),
            Text(measure, style: _label.copyWith(fontSize: 11.5)),
          ],
        ),
        const SizedBox(height: 6),
        Center(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ios = <Widget>[
      if (surfaces.contains(LiveSurface.compact))
        _section('Compact', '~44 pt por lado', LiveCompactPreview(config)),
      if (surfaces.contains(LiveSurface.minimal))
        _section(
          'Minimal (con otra actividad)',
          '37 × 37 pt',
          LiveMinimalPreview(config),
        ),
      if (surfaces.contains(LiveSurface.expanded))
        _section('Expandida', '~160 pt de alto', LiveExpandedPreview(config)),
      if (surfaces.contains(LiveSurface.lockScreen))
        _section(
          'Pantalla de bloqueo',
          'esquinas 22 pt',
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showLabels) ...[
                  const _LockClock(),
                  const SizedBox(height: 10),
                ],
                LiveLockScreenPreview(config),
              ],
            ),
          ),
        ),
    ];

    final children = <Widget>[
      if (ios.isNotEmpty)
        Container(
          padding: EdgeInsets.all(showLabels ? 14 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(showLabels ? 22 : 16),
            gradient: const RadialGradient(
              center: Alignment(-.6, -1),
              radius: 1.25,
              colors: [Color(0xFF3B5C7A), Color(0xFF1D2B3B), Color(0xFF0E1520)],
              stops: [0, .45, 1],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < ios.length; i++) ...[
                if (i > 0) SizedBox(height: showLabels ? 12 : 10),
                ios[i],
              ],
            ],
          ),
        ),
      if (surfaces.contains(LiveSurface.android)) LiveAndroidPreview(config),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          children[i],
        ],
      ],
    );
  }
}

class _LockClock extends StatelessWidget {
  const _LockClock();

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: const TextStyle(
      decoration: TextDecoration.none,
      color: Color(0xFFFFFFFF),
    ),
    child: const Column(
      children: [
        Text(
          '9:41',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.3,
            height: 1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        SizedBox(height: 10),
        Text(
          'domingo 4 de octubre',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xD9FFFFFF),
          ),
        ),
      ],
    ),
  );
}
